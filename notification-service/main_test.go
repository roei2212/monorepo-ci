package main

import "testing"

func TestHello(t *testing.T) {
    if Hello() != "Hello from notification-service" {
        t.Fail()
    }
}
