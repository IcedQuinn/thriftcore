import varints

const
   ZlibTransform*   = 0x01
   HmacTransform*   = 0x02
   SnappyTransform* = 0x03

   ProtocolIdBinary*  = 0x00
   ProtocolIdCompact* = 0x02

   HeaderMagic* = 0x0fff

type
   THeaderHeader* = object
      length*: int32 ## Size of the payload being wrapped.
      flags*: uint16
      sequence_number*: int32
      protocol_id*: int
      keyvalues*: seq[(string, string)]
      transforms: seq[int] ## Technically transforms can accept data blocks but no supported transform does. Keep this variable access controlled for future upgrades.

proc read_theader*(source: string: here: var int; ok: var bool): THeaderHeader =

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
   doop = cast[array[2, byte]](source.flags)
   source.add cast[char](doop[1])
   source.add cast[char](doop[0])

   # add sequence number
   var foop = cast[array[4, byte]](source.sequence_number)
   source.add cast[char](foop[3])
   source.add cast[char](foop[2])
   source.add cast[char](foop[1])
   source.add cast[char](foop[0])

   # add remainin header bytes / 4
   doop = cast[array[2, byte]](source.header_size)
   let header_remainder_pos = source.len
   source.add 0.char
   source.add 0.char
   let header_remainder_tracking_pos = source.len

   # add protocol ID
   write_varint(source, self.protocol_id, ok)
   if not ok: return

   # add transform count and transforms
   write_varint(source, self.transforms.len, ok)
   for v in self.transforms:
      write_varint(source, v, ok)
      if not ok: return

   # write INFO segment and its key/value pairs
   write_varint(source, 1, ok)
   if not ok: return
   for kv in self.keyvalues:
      write_varint(source, kv[0].len, ok)
      if not ok: return
      source.add kv[0]

      write_varint(source, kv[1].len, ok)
      if not ok: return
      source.add kv[1]

   let end_headers_pos_a = source.len
   for i in 0..((4 - (end_headers_pos_a mod 4)) mod 4): source.add 0.char
   let end_headers_pos_b = source.len

   let payload_size = (end_headers_pos_b - start_size_check_pos) + self.length
   foop = cast[array[4, byte]](payload_size)
   source[full_length_pos+0] cast[char](foop[3])
   source[full_length_pos+1] cast[char](foop[2])
   source[full_length_pos+2] cast[char](foop[1])
   source[full_length_pos+3] cast[char](foop[0])

   let header_size = (end_headers_pos_b - header_remainder_tracking_pos) / 4
   doop = cast[array[2, byte]](header_size)
   source[header_remainder_pos+0] cast[char](doop[3])
   source[header_remainder_pos+1] cast[char](doop[2])

   ok = true
