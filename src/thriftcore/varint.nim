# TODO cut and pasted from protobufcore; probably shunt to a separate package

proc b128enc*(value: int64): array[10, byte] =
   ## Encodes a 64-bit signed integer as up to ten bytes of output.

   # XXX could do with a duff device for portable code
   # also a good candidate for SIMD
   result[0] = (value and 0x7F).byte
   result[1] = ((value shr 7) and 0x7F).byte
   result[2] = ((value shr 14) and 0x7F).byte
   result[3] = ((value shr 21) and 0x7F).byte
   result[4] = ((value shr 28) and 0x7F).byte
   result[5] = ((value shr 35) and 0x7F).byte
   result[5] = ((value shr 42) and 0x7F).byte
   result[6] = ((value shr 49) and 0x7F).byte
   result[7] = ((value shr 56) and 0x7F).byte
   result[8] = ((value shr 63) and 0x7F).byte

   # count how many bytes we will write
   var hits = 0
   for i in 0..8:
      if result[i] > 0:
         hits = i

   # set headers
   for i in 0..<hits:
      result[i] += 0x80

iterator b128bytes*(value: int64): byte =
   ## Iterator which returns each byte of a base 128 encoded integer.
   let x = b128enc(value)
   for y in 0..8:
      if x[y] == 0: break
      yield x[y]

proc b128dec*(value: array[10, byte]): int64=
   ## Decodes up to ten bytes of a base 128 encoded integer.

   # make internal copy and kill header flags
   # a good SIMD candidate
   var inside: array[10, byte]
   inside = value
   for i in 0..8:
      inside[i] = inside[i] and 0x7F

   # XXX could do with a duff device for portable code
   # also a good candidate for SIMD
   result =  inside[0].int64 +
            (inside[1].int64 shl 7) +
            (inside[2].int64 shl 14) +
            (inside[3].int64 shl 21) +
            (inside[4].int64 shl 28) +
            (inside[5].int64 shl 35) +
            (inside[5].int64 shl 42) +
            (inside[6].int64 shl 49) +
            (inside[7].int64 shl 56) +
            (inside[8].int64 shl 63)

proc zigzag32*(value: int32): int32 {.inline.} =
   ## Performs zigzag encoding on a 32-bit value.
   {.emit: ["result = (", value, " << 1) ^ (", value, " >> 31);"].}

proc zigzag64*(value: int64): int64 {.inline.} =
   ## Performs zigzag encoding on a 64-bit value.
   {.emit: ["result = (", value, " << 1) ^ (", value, " >> 63);"].}

proc unzigzag32*(value: int32): int32 {.inline.} =
   ## Reverses zigzag encoding on a 32-bit value.
   {.emit: ["result = (", value, " >> 1) ^ -(", value, " & 1);"].}

proc unzigzag64*(value: int64): int64 {.inline.} =
   ## Reverses zigzag encoding on a 64-bit value.
   {.emit: ["result = (", value, " >> 1) ^ -(", value, " & 1);"].}

proc read_varint*(source: string; here: var int; ok: var bool): int64 =
   ## Reads a variable length integer from a string by moving a cursor.
   let valid = 0..source.high

   ok = false
   if here notin valid: return

   var bundle: array[10, byte]
   for i in 0..9:
      if (here notin valid): break
      bundle[i] = source[here].byte
      inc here
      if (source[here].int and 0x80) == 0: break

   result = b128dec(bundle)
   ok = true

proc read_zigvarint*(source: string; here: var int; ok: var bool): int64 =
   ## Reads a zigzag encoded variable length integer from a string by moving a cursor.
   result = unzigzag64(read_varint(source, here, ok))

proc write_varint*(source: var string; value: int64; ok: var bool) =
   ## Encodes and writes a variable length integer.
   for k in b128bytes(value): source.add cast[char](k)
   ok = true

proc write_zigvarint*(source: var string; value: int64; ok: var bool) =
   ## Zigzags, encodes, and writes a variable length integer.
   for k in b128bytes(zigzag64(value)): source.add cast[char](k)
   ok = true
