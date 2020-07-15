# reconnect that Magic Mouse
btcc() {
  btc $(btc | grep "Magic Mouse" | cut -c-17)
}
