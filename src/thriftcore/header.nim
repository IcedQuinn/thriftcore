import varint

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
      length*: int32 ## Size of the payload being wrapped.
      flags*: uint16
      sequence_number*: int32
      protocol_id*: int
      key_values*: seq[(string, string)]
      transforms: seq[int] ## Technically transforms can accept data blocks but no supported transform does. Keep this variable access controlled for future upgrades.

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
   let frame_length = cast[int32](lengthbyte)
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

   var sequencebyte: array[4, byte]
   if here+3 notin valid: return
   for i in 0..3:
      sequencebyte[3-i] = cast[byte](source[here])
      inc here

   var headersizebyte: array[2, byte]
   if here+1 notin valid: return
   for i in 0..1:
      headersizebyte[1-i] = cast[byte](source[here])
      inc here
   let headersize = cast[uint16](headersizebyte)
   let header_size_begins = here

   result.protocol_id = read_varint(source, here, ok).int
   if not ok: return

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
   let needle = header_size_begins + headersize.int
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
            let key = source.substr(here, here+klen.int)

            if here notin valid: return
            let vlen = read_varint(source, here, ok)
            if not ok: return
            if here+vlen notin valid: return
            let value = source.substr(here, here+klen.int)

            result.key_values.add (key, value)

      else:
         # we're allowed to skip remaining infos if we don't recognize one
         here = needle

   # correct length for payload only
   let header_stops_here = here
   result.length = (frame_length - (header_stops_here - length_tracking_starts)).int32

   ok = true

proc write_theader*(source: var string; value: THeaderHeader; ok: var bool) =
   ok = false

   # TODO endian nonsense; we assume host is little and we're posting to network byte order
   let full_length_pos = source.len
   source.add 0.char
   source.add 0.char
   source.add 0.char
   source.add 0.char
   let start_size_check_pos = source.len

   # add header magic
   var doop = cast[array[2, byte]](HeaderMagic)
   source.add cast[char](doop[1])
   source.add cast[char](doop[0])

   # add flags
   doop = cast[array[2, byte]](value.flags)
   source.add cast[char](doop[1])
   source.add cast[char](doop[0])

   # add sequence number
   var foop = cast[array[4, byte]](value.sequence_number)
   source.add cast[char](foop[3])
   source.add cast[char](foop[2])
   source.add cast[char](foop[1])
   source.add cast[char](foop[0])

   # add remainin header bytes / 4
   let header_remainder_pos = source.len
   source.add 0.char
   source.add 0.char
   let header_remainder_tracking_pos = source.len

   # add protocol ID
   write_varint(source, value.protocol_id, ok)
   if not ok: return

   # add transform count and transforms
   write_varint(source, value.transforms.len, ok)
   for v in value.transforms:
      write_varint(source, v, ok)
      if not ok: return

   # write INFO segment and its key/value pairs
   write_varint(source, InfoKeyValue, ok)
   if not ok: return
   for kv in value.keyvalues:
      write_varint(source, kv[0].len, ok)
      if not ok: return
      source.add kv[0]

      write_varint(source, kv[1].len, ok)
      if not ok: return
      source.add kv[1]

   let end_headers_pos_a = source.len
   for i in 0..((4 - (end_headers_pos_a mod 4)) mod 4): source.add 0.char
   let end_headers_pos_b = source.len

   let payload_size = (end_headers_pos_b - start_size_check_pos) + value.length
   foop = cast[array[4, byte]](payload_size)
   source[full_length_pos+0] = cast[char](foop[3])
   source[full_length_pos+1] = cast[char](foop[2])
   source[full_length_pos+2] = cast[char](foop[1])
   source[full_length_pos+3] = cast[char](foop[0])

   let header_size = (end_headers_pos_b - header_remainder_tracking_pos) / 4
   doop = cast[array[2, byte]](header_size)
   source[header_remainder_pos+0] = cast[char](doop[3])
   source[header_remainder_pos+1] = cast[char](doop[2])

   ok = true
