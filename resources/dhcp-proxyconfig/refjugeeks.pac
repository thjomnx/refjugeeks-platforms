//
// PAC file for refjugeeks LAN
//

function FindProxyForURL(url, host) {
    // If the hostname matches, send direct
    if (dnsDomainIs(host, "www.refjugeeks.net") || shExpMatch(host, "(*.refjugeeks.net|refjugeeks.net)"))
        return "DIRECT";

    // If the protocol or URL matches, send direct
    if (url.substring(0, 4) == "ftp:")
        return "DIRECT";

    // If the requested website is hosted within the internal network, send direct
    if (isPlainHostName(host) ||
        shExpMatch(host, "*.local") ||
        isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") ||
        isInNet(dnsResolve(host), "172.16.0.0",  "255.240.0.0") ||
        isInNet(dnsResolve(host), "192.168.0.0",  "255.255.0.0") ||
        isInNet(dnsResolve(host), "127.0.0.0", "255.255.255.0"))
        return "DIRECT";

    // Default: All other traffic, use below proxies, in fail-over order
    return "PROXY 192.168.0.3:8123; PROXY 192.168.0.4:8123";
}

