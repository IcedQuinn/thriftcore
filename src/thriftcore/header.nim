
const
   ZlibTransform*   = 0x01
   HmacTransform*   = 0x02
   SnappyTransform* = 0x03

   ProtocolIdBinary*  = 0x00
   ProtocolIdCompact* = 0x02

   HeaderMagic* = 0x0fff0000

type
   THeaderHeader* = object
      length*: int32 ## Remaining bytes in packet excluding this field.
      flags*: uint16
      header_size*: int16 ## Remaining 32-bit words in packet for the header. Do not include magic, flags or sequence number.
      sequence_number*: int32
      protocol_id*: int
      keyvalues*: seq[(string, string)]
      transforms: seq[int] ## Technically transforms can accept data blocks but no supported transform does. Keep this variable access controlled for future upgrades.

