package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	_ "net/http/pprof"
	"net/url"
	"time"

	"tailscale.com/client/tailscale"
	"tailscale.com/tsnet"
)

func httpLog(r *http.Request) {
	n := time.Now()
	fmt.Printf("%s (%s) [%s] \"%s %s\" %03d\n",
		r.RemoteAddr,
		n.Format(time.RFC822Z),
		r.Method,
		r.URL.Path,
		r.Proto,
		r.ContentLength,
	)
}

func main() {
	sName := flag.String("name", "", "server name we will be reverse proxying for")
	cIP := flag.String("ip", "127.0.0.1", "ip address to reverse proxy to")
	cPort := flag.Int("port", 5000, "port to reverse proxy to")
	prof := flag.Bool("prof", false, fmt.Sprintf("expose pprof on port %d", *cPort+1))
	flag.Parse()

	tsServer := &tsnet.Server{
		Hostname: *sName,
	}
	tsLocalClient := &tailscale.LocalClient{}
	tsLocalClient, err := tsServer.LocalClient()
	if err != nil {
		log.Fatal("can't get ts local client: ", err)
	}

	if *prof {
		go func() {
			log.Println(http.ListenAndServe(fmt.Sprintf("localhost:%d", *cPort+1), nil))
		}()
	}

	ln, err := tsServer.Listen("tcp", ":443")
	if err != nil {
		log.Fatal("can't listen: ", err)
	}

	rpURL, err := url.Parse(fmt.Sprintf("http://%s:%d", *cIP, *cPort))
	if err != nil {
		log.Fatal(err)
	}

	proxy := &httputil.ReverseProxy{Director: func(req *http.Request) {
		req.Header.Add("X-Forwarded-Host", req.Host)
		req.Header.Add("X-Origin-Host", rpURL.Host)
		req.URL.Scheme = rpURL.Scheme
		req.URL.Host = rpURL.Host
		httpLog(req)
	}}

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		proxy.ServeHTTP(w, r)
	})

	hs := &http.Server{
		Handler: mux,
		TLSConfig: &tls.Config{
			GetCertificate: tsLocalClient.GetCertificate,
		},
	}

	log.Panic(hs.ServeTLS(ln, "", ""))
}
