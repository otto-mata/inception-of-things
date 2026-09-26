package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
)

func cstring2string(ca []int8) string {
	s := make([]byte, len(ca))
	var lens int
	for ; lens < len(ca); lens++ {
		if ca[lens] == 0 {
			break
		}
		s[lens] = uint8(ca[lens])
	}
	return string(s[0:lens])
}

func uname() string {
	u := syscall.Utsname{}
	err := syscall.Uname(&u)
	if err != nil {
		return "UNAME ERROR"
	}
	return fmt.Sprintf("%s %s %s %s %s",
		cstring2string(u.Sysname[:]),
		cstring2string(u.Nodename[:]),
		cstring2string(u.Release[:]),
		cstring2string(u.Version[:]),
		cstring2string(u.Machine[:]),
	)
}

func main() {
	go func() {
		ctx, stop := signal.NotifyContext(
			context.Background(), syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL)
		defer stop()
		<-ctx.Done()
		log.Printf("%s\n", context.Cause(ctx).Error())
		os.Exit(0)
	}()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		podname, set := os.LookupEnv("KUBERNETES_POD_NAME")
		if !set {
			var err error
			podname, err = os.Hostname()
			if err != nil {
				podname = "ERR"
			}
		}
		special_message, set := os.LookupEnv("MESSAGE")
		if !set {
			special_message = "DEFAULT"
		}
		fmt.Fprintf(w, "msg: %s\npod: %s\nuname: %s\n",
			special_message,
			podname,
			uname(),
		)
	})
	log.Printf("Starting server on port 8080")
	log.Println(http.ListenAndServe(":8080", nil))
}
