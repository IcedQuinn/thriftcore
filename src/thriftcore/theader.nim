import macros, varint

const
   ZlibTransform*   = 0x01
   HmacTransform*   = 0x02
   SnappyTransform* = 0x03

   ProtocolIdBinary*  = 0x00
   ProtocolIdCompact* = 0x02

   InfoKeyValue* = 0x01

   HeaderMagic* = 0x0fff

type
   THeaderHeader* = object
      length*: uint32 ## Size of the payload being wrapped.
      flags*: uint16
      sequence_number*: uint32
      protocol_id*: int
      key_values*: seq[(string, string)]
      transforms: seq[int] ## Technically transforms can accept data blocks but no supported transform does. Keep this variable access controlled for future upgrades.

macro rnok(x: untyped): untyped =
   ## Call X then test if 'ok' is true otherwise return.
   ## Common idiom when testing if parsers were successful.
   result = quote:
      `x`
      if not ok: return

proc read_theader*(source: string; here: var int; ok: var bool): THeaderHeader =
   let valid = 0..source.high
   ok = false
   let mark = here
   defer:
      if not ok:
         here = mark

   var lengthbyte: array[4, byte]
   if here+3 notin valid: return
   for i in 0..3:
      lengthbyte[3-i] = cast[byte](source[here])
      inc here
   result.length = cast[uint32](lengthbyte)
   let length_tracking_starts = here

   var magicbyte: array[2, byte]
   if here+1 notin valid: return
   for i in 0..1:
      magicbyte[1-i] = cast[byte](source[here])
      inc here

   var flagsbyte: array[2, byte]
   if here+1 notin valid: return
   for i in 0..1:
      flagsbyte[1-i] = cast[byte](source[here])
      inc here
   result.flags = cast[uint16](flagsbyte)

   var sequencebyte: array[4, byte]
   if here+3 notin valid: return
   for i in 0..3:
      sequencebyte[3-i] = cast[byte](source[here])
      inc here
   result.sequence_number = cast[uint32](sequencebyte)

   var headersizebyte: array[2, byte]
   if here+1 notin valid: return
   for i in 0..1:
      headersizebyte[1-i] = cast[byte](source[here])
      inc here
   let headersize = cast[uint16](headersizebyte)
   let header_size_begins = here

   rnok: result.protocol_id = read_varint(source, here, ok).int

   let transform_count = read_varint(source, here, ok).int
   if not ok: return
   for i in 0..<transform_count:
      let transform = read_varint(source, here, ok)
      if not ok: return
      case transform
      of ZlibTransform, HmacTransform, SnappyTransform:
         result.transforms.add transform.int
      else:
         # XXX no way to feedback this is unsupported transform
         return

   # now we read header pairs until we run out of data or hit an unknown
   let needle = header_size_begins + (headersize.int * 4)
   while here < needle:
      let info_id = read_varint(source, here, ok)
      if not ok: return
      case info_id:
      of InfoKeyValue:
         let count = read_varint(source, here, ok)
         if not ok: return
         for i in 0..<count:
            if here notin valid: return
            let klen = read_varint(source, here, ok)
            if not ok: return
            if here+klen notin valid: return
            let key = source.substr(here, here+(klen.int-1))
            inc here, klen.int

            if here notin valid: return
            let vlen = read_varint(source, here, ok)
            if not ok: return
            if here+vlen notin valid: return
            let value = source.substr(here, here+(vlen.int-1))
            inc here, vlen.int

            result.key_values.add((key, value))

      else:
         # we're allowed to skip remaining infos if we don't recognize one
         here = needle

   # make sure to skip past the padding too
   here = needle

   # correct length for payload only
   let header_stops_here = here
   result.length -= (header_stops_here - length_tracking_starts).uint32

   ok = true

proc pad*(source: var string; amount: int) =
   for i in 0..<amount: source.add 0.char

proc put_u16be*(source: var string; v: uint16) =
   var doop = cast[array[2, byte]](v)
   source.add cast[char](doop[1])
   source.add cast[char](doop[0])

proc put_u32be*(source: var string; v: uint32) =
   var foop = cast[array[4, byte]](v)
   source.add cast[char](foop[3])
   source.add cast[char](foop[2])
   source.add cast[char](foop[1])
   source.add cast[char](foop[0])

proc set_u16be*(source: var string; v: uint16; at: int) =
   var foop = cast[array[4, byte]](v)
   source[at+0] = cast[char](foop[1])
   source[at+1] = cast[char](foop[0])

proc set_u32be*(source: var string; v: uint32; at: int) =
   var foop = cast[array[4, byte]](v)
   source[at+0] = cast[char](foop[3])
   source[at+1] = cast[char](foop[2])
   source[at+2] = cast[char](foop[1])
   source[at+3] = cast[char](foop[0])

proc write_theader*(source: var string; value: THeaderHeader; ok: var bool) =
   ok = false

   # TODO endian nonsense; we assume host is little and we're posting to network byte order
   let full_length_pos = source.len
   pad(source, 4)
   let start_size_check_pos = source.len

   put_u16be(source, HeaderMagic) # add header magic
   put_u16be(source, value.flags) # add flags
   put_u32be(source, value.sequence_number) # add sequence number

   # add remainin header bytes / 4
   let header_remainder_pos = source.len
   pad(source, 2)
   let header_remainder_tracking_pos = source.len

   # add protocol ID
   rnok: write_varint(source, value.protocol_id, ok)

   # add transform count and transforms
   rnok: write_varint(source, value.transforms.len, ok)
   for v in value.transforms:
      rnok: write_varint(source, v, ok)

   # write INFO segment and its key/value pairs
   rnok: write_varint(source, InfoKeyValue, ok)
   rnok: write_varint(source, value.keyvalues.len, ok)
   for kv in value.keyvalues:
      rnok: write_varint(source, kv[0].len, ok)
      source.add kv[0]

      rnok: write_varint(source, kv[1].len, ok)
      source.add kv[1]

   let end_headers_pos_a = source.len

   # make sure header size is padded to word boundary
   let hsize = end_headers_pos_a - header_remainder_tracking_pos
   let hmod = (hsize mod 4)
   if hmod > 0:
      for i in hmod..<4: source.add 0.char

   let end_headers_pos_b = source.len

   let payload_size = (end_headers_pos_b - start_size_check_pos).uint32 + value.length
   set_u32be(source, payload_size, full_length_pos)

   let sanity = (end_headers_pos_b - header_remainder_tracking_pos) mod 4
   assert sanity == 0

   let header_size = (end_headers_pos_b - header_remainder_tracking_pos) div 4
   set_u16be(source, header_size.uint16, header_remainder_pos)

   ok = true

when is_main_module:
   var h: THeaderHeader
   h.length = 32
   h.protocol_id = ProtocolIdCompact
   h.sequence_number = 1337
   h.keyvalues.add ("spudger", "bongled")
   h.keyvalues.add ("jwt", "shittified")

   echo h
   var buf: string
   var here: int
   var ok: bool
   write_theader(buf, h, ok)
   assert ok == true
   buf.add "xxx"

   var h2 = read_theader(buf, here, ok)
   assert ok == true
   echo h2

   assert h.length == h2.length
   assert h.flags == h2.flags
   assert h.sequence_number == h2.sequence_number
   assert h.protocol_id == h2.protocol_id
   assert h.key_values == h2.key_values
   assert h.transforms == h2.transforms

