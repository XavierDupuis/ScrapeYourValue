#!/bin/sh

print() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1"
}

log() {
    print "⚡ $1"
}

warn() {
    print "🟠 $1"
}