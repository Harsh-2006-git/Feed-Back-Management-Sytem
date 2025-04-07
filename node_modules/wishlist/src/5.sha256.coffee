# Why use SHA-256? Is it OK to use CRC32? My answer is:
# The reason is for security. There's a potential issue if we use a weak algorithm.
# If some tests involve "get info from the web", then an attacker may be able to affect the units'
# true/false results such that it produces the same checksum as before.
# For example, we have 5000 units. At least 500 of them involve "get info from the web".
# A web attacker just need to tamper with these 500 to forge the whole 5000's checksum,
# so the developer will believe the results haven't changed but actually many of 5000 have.
# These are "user"-caused collisions, which need to be avoided logically, though
# it's safe when all traffic is under HTTPS or IPsec.
#
# In contrast, it's not necessary when it comes to "developer"-caused deliberate
# collisions, like the 18-digit numbers in many of my repos.
# If another library later uses this name, we can simply
# discard this evil library and choose another.
#
# I strictly followed the steps on:
# http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf
# In doing math power and division, I use `round` to avoid possible fractions in old engine.

wishlist.sha256 = (str) ->
    if str.length > Math.round(Math.pow(2, 31) - 1)
        throw new Error()
    wordToString = (n) -> (((n >>> (i * 4)) % 16).toString(16) for i in [7..0]).join("")
    add = ->
        r = 0
        for arg in arguments
            r = (r + arg) % 0x100000000
        r
    ROTR = (x, n) -> x >>> n | x << (32 - n)
    SHR = (x, n) -> x >>> n
    Ch = (x, y, z) -> (x & y) ^ (~x & z)
    Maj = (x, y, z) -> (x & y) ^ (x & z) ^ (y & z)
    SIGMA0 = (x) -> ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22)
    SIGMA1 = (x) -> ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25)
    sigma0 = (x) -> ROTR(x, 7) ^ ROTR(x, 18) ^ SHR(x, 3)
    sigma1 = (x) -> ROTR(x, 17) ^ ROTR(x, 19) ^ SHR(x, 10)
    K = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ]
    # preprocessing ========================================[
    H = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
    bytes = str.split("").map((m) -> m.charCodeAt(0))
    l = str.length * 8
    k = 448 - l - 1
    while k < 0
        k += 512
    paddedLength = l + 1 + k + 64
    bytes.push(0x80)
    for i in [0...Math.round((k - 7) / 8)]
        bytes.push(0)
    # This only supports max length of 2^32. But it's enough for testing. -----[
    bytes.push(0)
    bytes.push(0)
    bytes.push(0)
    bytes.push(0)
    bytes.push(l >>> 24)
    bytes.push((l >>> 16) % 256)
    bytes.push((l >>> 8) % 256)
    bytes.push(l % 256)
    # ]--------------------
    N = Math.round(paddedLength / 512)
    M = new Array(N)
    for i in [0...N]
        M[i] = new Array(16)
        for j in [0...16]
            offset = i * 64 + j * 4
            M[i][j] = (bytes[offset] << 24) | (bytes[offset + 1] << 16) |
                    (bytes[offset + 2] << 8) | bytes[offset + 3]
    # ]==================== hash computation ====================[
    W = new Array(64)
    for i in [0...N]
        for t in [0...64]
            W[t] =
                if t < 16
                    M[i][t]
                else
                    add(sigma1(W[t - 2]), W[t - 7], sigma0(W[t - 15]), W[t - 16])
        a = H[0]
        b = H[1]
        c = H[2]
        d = H[3]
        e = H[4]
        f = H[5]
        g = H[6]
        h = H[7]
        for t in [0...64]
            T1 = add(h, SIGMA1(e), Ch(e, f, g), K[t], W[t])
            T2 = add(SIGMA0(a), Maj(a, b, c))
            h = g
            g = f
            f = e
            e = add(d, T1)
            d = c
            c = b
            b = a
            a = add(T1, T2)
        H[0] = add(a, H[0])
        H[1] = add(b, H[1])
        H[2] = add(c, H[2])
        H[3] = add(d, H[3])
        H[4] = add(e, H[4])
        H[5] = add(f, H[5])
        H[6] = add(g, H[6])
        H[7] = add(h, H[7])
    # ]========================================
    H.map((m) -> wordToString(m)).join("")
