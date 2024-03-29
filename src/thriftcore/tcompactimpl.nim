import varint

type
   CompactElementType* = enum
      cetUnknown
      cetBoolTrue
      cetBoolFalse
      cetI8
      cetI16
      cetI32
      cetI64
      cetDouble
      cetBinary
      cetList
      cetSet
      cetMap
      cetStruct

   CompactMessageType* = enum
      cmtUnknown   ## Error value.
      cmtCall      ## Call going out on the wire.
      cmtReply     ## Reply to a previous request.
      cmtException ## An error across the wire.
      cmtOneway    ## Call going out that does not anticipate a reply.

   CompactMessageHeader* = object
      protocol_id*, version*: int
      message_type*: CompactMessageType
      sequence_id*: int32
      name*: string

   CompactEvent* = object
      case kind*: CompactElementType
      of cetUnknown, cetBoolTrue, cetBoolFalse:
         discard
      of cetI8, cetI16, cetI32, cetI64:
         ivalue*: int64
      of cetDouble:
         dvalue*: float64
      of cetBinary:
         length*: int64
      of cetStruct:
         field*: int16
         inner_struct_type*: CompactElementType
      of cetList, cetSet:
         list_length*: int32
         inner_list_type*: CompactElementType
      of cetMap:
         map_elements*: int32
         key_type*, value_type*: CompactElementType

proc to_byte*(cet: CompactElementType): byte =
   case cet:
   of cetBoolTrue: return 1
   of cetBoolFalse: return 2
   of cetI8: return 3
   of cetI16: return 4
   of cetI32: return 5
   of cetI64: return 6
   of cetDouble: return 7
   of cetBinary: return 8
   of cetList: return 9
   of cetSet: return 10
   of cetMap: return 11
   of cetStruct: return 12
   of cetUnknown: return 0 # XXX maybe throw a defect?

proc to_cet*(b: byte): CompactElementType =
   case b
   of 1: return cetBoolTrue
   of 2: return cetBoolFalse
   of 3: return cetI8
   of 4: return cetI16
   of 5: return cetI32
   of 6: return cetI64
   of 7: return cetDouble
   of 8: return cetBinary
   of 9: return cetList
   of 10: return cetSet
   of 11: return cetMap
   of 12: return cetStruct
   else:
      return cetUnknown

proc to_byte*(cmt: CompactMessageType): byte =
   case cmt
   of cmtCall: return 1
   of cmtReply: return 2
   of cmtException: return 3
   of cmtOneway: return 4
   of cmtUnknown: return 0 # XXX maybe throw a defect?

proc to_cmt*(cmt: int): CompactMessageType =
   case cmt
   of 1: return cmtCall
   of 2: return cmtReply
   of 3: return cmtException
   of 4: return cmtOneway
   else:
      # XXX maybe throw a defect?
      return cmtUnknown

proc field_fits_nibble*(value: int): bool =
   return value >= 0 and value < 0x0F

proc read_struct_field_header*(source: string; last_field: var int16; here: var int; ok: var bool): CompactEvent =
   ## last_field is used to resolve field offset deltas.
   ok = false
   let mark = here
   let loof = last_field
   let valid = 0..source.high
   result = CompactEvent(kind: cetStruct)
   defer:
      if not ok:
         here = mark
         last_field = loof

   if here notin valid: return
   let h = source[here].uint8
   inc here
   if here notin valid: return

   let hlo = h and 0x0F
   let hhi = (h and 0xF0) shr 4

   result.inner_list_type = to_cet(hlo)

   if hhi > 0:
      # this is a delta
      inc last_field, hhi.int
   else:
      last_field = read_zigvarint(source, here, ok).int16
      if not ok: return

   result.field = last_field
   ok = true

proc read_list_header*(source: string; here: var int; ok: var bool): CompactEvent =
   ## Reads a list heading.
   let mark = here
   let valid = 0..source.high
   ok = false
   if here notin valid: return
   defer:
      if not ok:
         here = mark

   let h = source[here].uint8
   inc here
   if here notin valid: return

   let hlo = h and 0x0F
   let hhi = (h and 0xF0) shr 4

   result = CompactEvent(kind: cetList)
   result.inner_list_type = to_cet(hlo)
   # NB bool lists are typed as cetBoolFalse in this header
   # their values are single bytes 0 or 1

   if hhi < 0x0F:
      result.list_length = hhi.int32
   else:
      result.list_length = read_zigvarint(source, here, ok).int16
      if not ok: return

   ok = true

proc read_set_header*(source: string; here: var int; ok: var bool): CompactEvent =
   ## Reads a list heading and if successful, marks it as a set instead.
   result = read_list_header(source, here, ok)
   if ok:
      result.kind = cetSet

proc read_map_header*(source: string; here: var int; ok: var bool): CompactEvent =
   ## Reads a map header.
   let valid = 0..source.high
   let mark = here
   ok = false
   if here notin valid: return
   defer:
      if not ok:
         here = mark

   result = CompactEvent(kind: cetMap)

   result.map_elements = read_zigvarint(source, here, ok).int32
   if not ok: return
   if here notin valid: return

   let h = source[here].uint8
   inc here

   let hlo = h and 0x0F
   let hhi = (h and 0xF0) shr 4

   result.key_type = to_cet(hhi)
   result.value_type = to_cet(hlo)

   ok = true

proc read_message_header*(source: string; here: var int; ok: var bool): CompactMessageHeader =
   let valid = 0..source.high
   let mark = here
   ok = false
   if here notin valid: return
   defer:
      if not ok:
         here = mark

   result.protocol_id = source[here].int
   inc here
   if here notin valid: return

   let h = source[here].uint8
   inc here
   if here notin valid: return

   let hlo = h and 0x37
   let hhi = (h and 0xE0) shr 5

   result.message_type = to_cmt(hhi.int)
   result.version = hlo.int

   result.sequence_id = read_varint(source, here, ok).int32
   if here notin valid: return

   let namelen = read_zigvarint(source, here, ok)
   if here notin valid: return

   let needle = here + namelen
   if needle notin valid: return
   result.name = source.substr(here.int, needle.int)
   inc here, namelen.int

   ok = true

proc write_binary*(source: var string; payload: string; ok: var bool) =
   write_varint(source, payload.len.int64, ok)
   source.add payload
   ok = true

# NB compact protocol uses little endian because someone goofed back in the day

proc read_double*(source: string; here: var int; ok: var bool): float64 =
   let valid = 0..source.high
   ok = false
   if here notin valid: return
   if here+7 notin valid: return

   var buffer: array[8, byte]
   for i in 0..7:
      buffer[i] = source[here].byte
      inc here

   result = cast[float64](buffer)

proc write_double*(source: var string; payload: float64; ok: var bool) =
   var buffer = cast[array[8, byte]](payload)
   for i in 0..7: source.add cast[char](buffer[i])
   ok = true

proc write_listset_bool*(source: var string; payload: bool; ok: var bool) =
   if payload:
      source.add cast[char](1)
   else:
      source.add cast[char](0)
   ok = true

proc write_close_byte*(source: var string; ok: var bool) =
   ## Writes a nil byte. Needed to write empty maps, or close structures.
   source.add 0.char
   ok = true

proc write_struct_header*(source: var string; field_type: CompactElementType; field_id: int16; last_id: var int16; ok: var bool) =
   ## Writes the header for a struct entry.
   ## last_field is used to support differential encoding of field IDs.

   let gap = last_id.int - field_id.int

   if field_fits_nibble(gap):
      source.add cast[char]((gap.byte shl 4) + to_byte(field_type))
   else:
      let size = cast[array[2, byte]](field_id)
      source.add cast[char](to_byte(field_type))
      source.add cast[char](size[0])
      source.add cast[char](size[1])

   last_id = field_id
   ok = true

proc write_listset_header*(source: var string; value_type: CompactElementType; count: int; ok: var bool) =
   if count < 0:
      ok = false
      return

   if count < 15:
      source.add cast[char]((count.byte shr 4) + to_byte(value_type))
      write_varint(source, count, ok)
      if not ok: return
   else:
      source.add cast[char](0xF0 + to_byte(value_type))

   ok = true

proc write_map_header*(source: var string; key_type, value_type: CompactElementType; count: int; ok: var bool) =
   if count < 0:
      ok = false
      return

   if count == 0:
      source.add 0.char
   else:
      write_varint(source, count, ok)
      if not ok: return

   source.add cast[char]((to_byte(key_type) shl 4) + to_byte(value_type))

   ok = true

when is_main_module:
   block:
      let a = b128enc(1)
      assert a[0] == 1
      assert b128dec(a) == 1

      let b = b128enc(300)
      assert b[0] == 172
      assert b[1] == 2
      assert b128dec(b) == 300

      let c = b128enc(50399)
      assert c[0] == 0xDF
      assert c[1] == 0x89
      assert c[2] == 0x03
      assert b128dec(c) == 50399

      assert zigzag32( 0) == 0
      assert zigzag32(-1) == 1
      assert zigzag32( 1) == 2
      assert zigzag32(-2) == 3

      assert unzigzag32(zigzag32(1337)) == 1337
      assert unzigzag32(zigzag32(-1337)) == -1337

