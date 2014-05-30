boxdigest = require('box.digest')
type(boxdigest)

boxdigest.md4_hex()
boxdigest.md5_hex()
boxdigest.sha_hex()
boxdigest.sha1_hex()
boxdigest.sha224_hex()
boxdigest.sha256_hex()
boxdigest.sha384_hex()
boxdigest.sha512_hex()

string.len(boxdigest.md4_hex())
string.len(boxdigest.md5_hex())
string.len(boxdigest.sha_hex())
string.len(boxdigest.sha1_hex())
string.len(boxdigest.sha224_hex())
string.len(boxdigest.sha256_hex())
string.len(boxdigest.sha384_hex())
string.len(boxdigest.sha512_hex())

string.len(boxdigest.md4())
string.len(boxdigest.md5())
string.len(boxdigest.sha())
string.len(boxdigest.sha1())
string.len(boxdigest.sha224())
string.len(boxdigest.sha256())
string.len(boxdigest.sha384())
string.len(boxdigest.sha512())

boxdigest.md5_hex(123)
boxdigest.md5_hex('123')
boxdigest.md5_hex(true)
boxdigest.md5_hex('true')
boxdigest.md5_hex(nil)
boxdigest.md5_hex()

boxdigest.crc32()
boxdigest.crc32_update(4294967295, '')

boxdigest.crc32('abc')
boxdigest.crc32_update(4294967295, 'abc')

boxdigest.crc32('abccde')
boxdigest.crc32_update(boxdigest.crc32('abc'), 'cde')
