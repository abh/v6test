package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"reflect"
	"strconv"
	"strings"
	"time"

	"github.com/kr/beanstalk"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/gorilla/schema"
	"github.com/kr/pretty"
)

type Latency int64

type LogData struct {
	Timev4  Latency `json:"ipv4,omitempty"   schema:"ipv4"`
	Timev6  Latency `json:"ipv6,omitempty"   schema:"ipv6"`
	Timev64 Latency `json:"ipv64,omitempty"  schema:"ipv64"`

	IPv4 string `json:"ipv4_ip,omitempty"  schema:"ipv4_ip"`
	IPv6 string `json:"ipv6_ip,omitempty"  schema:"ipv6_ip"`
	Iv64 string `json:"ipv64_ip,omitempty" schema:"ipv64_ip"`

	Site    string `json:"site,omitempty"`
	UserID  string `json:"v6uq"  schema:"v6uq"`
	Version string `json:"version"`

	UserAgent string `json:"user-agent" schema:"-"`
	Time      int64  `json:"time" schema:"-"`
	Referrer  string `json:"referrer" schema:"-"`
	RemoteIP  string `json:"remote_ip"  schema:"-"`
	Host      string `json:"host" schema:"-"`

	Callback string `json:"-"`
}

var (
	flagip       = flag.String("ip", "", "Listen on this IP address")
	flaghttpport = flag.String("httpport", "6062", "Set the HTTP port")
)

var decoder *schema.Decoder
var beanCh chan []byte
var localNets []*net.IPNet

func init() {

	beanCh = make(chan []byte, 200)

	decoder = schema.NewDecoder()
	decoder.ZeroEmpty(true)
	decoder.IgnoreUnknownKeys(true)
	decoder.RegisterConverter(Latency(0), func(v string) reflect.Value {
		i, err := strconv.Atoi(v)
		if err != nil {
			l := Latency(0)
			return reflect.ValueOf(l)
		}
		l := Latency(i)
		return reflect.ValueOf(l)
	})

	pn := []string{"10.220.0.0/24", "207.171.3.0/27"}
	for _, p := range pn {
		_, ipnet, err := net.ParseCIDR(p)
		if err != nil {
			panic(err)
		}
		localNets = append(localNets, ipnet)
	}
}

func main() {
	flag.Parse()
	go beanstalkWorker()
	httpHandler()
}

func beanstalkWriter() error {

	bean, err := beanstalk.Dial("tcp", "127.0.0.1:11300")
	if err != nil {
		return fmt.Errorf("Could not connect to beanstalkd: %s", err)
	}

	tube := beanstalk.Tube{bean, "v6-results"}

	for {
		js, ok := <-beanCh
		if !ok {
			return fmt.Errorf("Could not read from channel")
		}
		_, err := tube.Put(js, 100, 0, 120*time.Second)
		if err != nil {
			return fmt.Errorf("Could not put job: %s", err)
		}
	}
}

func beanstalkWorker() {
	for {
		err := beanstalkWriter()
		if err != nil {
			log.Printf("error writing to beanstalkd: %s", err)
		}
		time.Sleep(2 * time.Second)
	}
}

func saveHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/javascipt")
	w.Header().Set("Cache-Control", "private, no-cache, no-store, must-revalidate")

	w.WriteHeader(204)

	err := r.ParseForm()
	if err != nil {
		log.Printf("Could not parse form: %s", err)
	}

	data := LogData{}
	err = decoder.Decode(&data, r.Form)
	if err != nil {
		log.Printf("Could decode form: %s", err)
	}

	data.RemoteIP = remoteIP(r)
	data.Time = time.Now().Unix()

	data.Referrer = r.Header.Get("Referer")
	data.UserAgent = r.Header.Get("User-Agent")
	data.Host = r.Host
	if idx := strings.Index(data.Host, ":"); idx > 0 {
		data.Host = data.Host[0:idx]
	}

	js, err := json.Marshal(&data)
	if err != nil {
		log.Printf("Could not marshal json: %s", err)
	}

	pretty.Println(string(js))
	beanCh <- js
}

func localNet(ip net.IP) bool {
	for _, n := range localNets {
		if n.Contains(ip) {
			return true
		}
	}
	return false
}

func remoteIP(r *http.Request) string {
	xff := r.Header.Get("X-Forwarded-For")
	if len(xff) > 0 {
		ips := strings.Split(xff, ",")
		for i := len(ips) - 1; i >= 0; i-- {
			ip := strings.TrimSpace(ips[i])
			nip := net.ParseIP(ip)
			if nip != nil {
				if localNet(nip) {
					continue
				}
				return nip.String()
			}
		}
	}

	ip, _, _ := net.SplitHostPort(r.RemoteAddr)
	return ip
}

func ipHandler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	cb := r.Form.Get("callback")
	if len(cb) == 0 {
		w.WriteHeader(400)
		return
	}

	ip := remoteIP(r)
	defer r.Body.Close()

	w.Header().Set("Content-Type", "text/javascipt")
	w.Header().Set("Cache-Control", "private, no-cache, no-store, must-revalidate")

	resp := []byte{}
	resp = append(resp, cb...)
	resp = append(resp, `({"ip":"`...)
	resp = append(resp, ip...)
	resp = append(resp, `"})`...)
	resp = append(resp, '\n')

	w.WriteHeader(200)
	w.Write(resp)

}

func setupMux() *mux.Router {
	r := mux.NewRouter()
	r.HandleFunc("/c/ip", ipHandler)
	r.HandleFunc("/c/json", saveHandler)
	r.PathPrefix("/").Handler(http.FileServer(http.Dir("public/")))
	return r
}

func httpHandler() {

	listen := *flagip + ":" + *flaghttpport
	srv := &http.Server{
		Handler:      handlers.CombinedLoggingHandler(os.Stdout, setupMux()),
		Addr:         listen,
		WriteTimeout: 5 * time.Second,
		ReadTimeout:  5 * time.Second,
	}
	log.Println("HTTP listen on", listen)
	log.Fatal(srv.ListenAndServe())

}
