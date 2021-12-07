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
      header_size*: int16 ## Remaining 32-bit words in packet for the header. Do not include magic, flags or sequence number.
      sequence_number*: int32
      protocol_id*: int
      keyvalues*: seq[(string, string)]
      transforms: seq[int] ## Technically transforms can accept data blocks but no supported transform does. Keep this variable access controlled for future upgrades.

proc read_theader*(source: string: here: var int; ok: var bool): THeaderHeader =

proc write_theader*(source: var string; value: THeaderHeader; ok: var bool) =
   ok = false

   # TODO increase length to account for entire header block
   # TODO increase header size

   # TODO endian nonsense; we assume host is little and we're posting to network byte order
   let full_length = source.len
   source.add 0.char
   source.add 0.char
   source.add 0.char
   source.add 0.char

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
   source.add 0.char
   source.add 0.char

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

   ok = true
