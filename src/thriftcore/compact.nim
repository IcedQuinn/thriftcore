import protocol, compactimpl, varints

type
   Protocol* = object of RootObj

const
   ENotImplemented = "Method not implemented."

converter to_cet(kind: TypeKind): CompactElementType =
   case kind
   of tkI16: return cetI16
   of tkI32: return cetI32
   of tkI64: return cetI64
   of tkStruct: return cetStruct
   of tkMap: return cetMap
   of tkList: return cetList
   of tkSet: return cetSet
   of tkBool: return cetBoolFalse
   of tkByte: return cetI8
   of tkDouble: return cetDouble
   of tkString: return cetString

converter to_typekind(kind: TypeKind): CompactElementType =
   case kind
   of cetI16: return tkI16
   of cetI32: return tkI32
   of cetI64: return tkI64
   of cetStruct: return tkStruct
   of cetMap: return tkMap
   of cetList: return tkList
   of cetSet: return tkSet
   of cetBoolTrue, cetBoolFalse: return tkBool
   of cetI8: return tkByte
   of cetDouble: return tkDouble
   of cetString: return tkString

#/-
#| Write messages
#\-

method write_message_begin*(
   self: ref CompactProtocol;
   name: string;
   kind: MessageKind;
   sequence_number: uint32) =
      # TODO refactor this to a write_message_header call in compactimpl
      var ok: bool
      # TODO better exception
      if name.len == 0: raise new_exception(Exception, "Message name may not be empty.")

      self.buffer.add cast[char](0x82)

      var mt: int
      case kind
      of mkCall: mt = 1
      of mkReply: mt = 2
      of mkException: mt = 3
      of mkOneway: mt = 4
      mt = (mt shl 4) + 1

      self.buffer.add cast[char](mt)
      put_u32be(self.buffer, sequence_number)
      write_varint(self,buffer, name.len, ok)
      source.add name

method write_message_end*(
   self: ref CompactProtocol) =
      discard # no message trailer

method write_struct_begin*(
   self: ref CompactProtocol;
   name: string) =
      self.last_id.add 0
      self.list_or_set.add false

method write_struct_end*(
   self: ref CompactProtocol) =
      if self.last_id.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      write_close_byte(self.buffer) # end with a single null
      self.last_id.pop
      self.list_or_set.pop

method write_field_begin*(
   self: ref CompactProtocol;
   name: string;
   kind: TypeKind;
   id: int) =
      var lid = self.last_field[self.last_field.high]
      write_struct_header(self.buffer, kind, lid, id)
      self.last_field[self.last_field.high] = lid

method write_field_end*(
   self: ref CompactProtocol) =
      discard # end of field has no marker

method write_field_stop*(
   self: ref CompactProtocol) =
      write_close_byte(self.buffer)

method write_map_begin*(
   self: ref CompactProtocol;
   key_kind, value_kind: TypeKind;
   size: int) =
      write_map_header(self.buffer, key_kind, value_kind, size)
      self.list_or_set.add true

method write_map_end*(
   self: ref CompactProtocol) =
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.list_or_set.pop
      discard # nothing to encode

method write_list_begin*(
   self: ref CompactProtocol;
   name: string;
   value_kind: TypeKind;
   size: int) =
      self.list_or_set.add true
      write_listset_header(self.buffer, element_kind, size)

method write_list_end*(
   self: ref CompactProtocol) =
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.list_or_set.pop
      discard # nothing to encode

method write_set_begin*(
   self: ref CompactProtocol;
   element_kind: TypeKind;
   size: int) =
      self.list_or_set.add true
      write_listset_header(self.buffer, element_kind, size)

method write_set_end*(
   self: ref CompactProtocol) =
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.list_or_set.pop
      discard # nothing to encode

method write_bool*(
   self: ref CompactProtocol;
   value: bool) =
      # bools are encoded either as a byte (in lists, sets and maps) or
      # as a different type code if a struct field
      if self.list_or_set[self.list_or_set.high]:
         # encode as a 0 or a 1
         write_listset_bool(self.buffer, value)
      else:
         if value:
            # tricky; have to decrement the type code by one
            let x = self.buffer[self.buffer.high]
            let y = cast[char](cast[byte](x) - 1)
            self.buffer[self.buffer.high] = y
         else:
            discard # encoded as false by default so we're done

method write_byte*(
   self: ref CompactProtocol;
   value: byte) =
      var ok: bool
      write_varint(self.buffer, value, ok)

method write_i16*(
   self: ref CompactProtocol;
   value: int16) =
      var ok: bool
      write_varint(self.buffer, value, ok)

method write_i32*(
   self: ref CompactProtocol;
   value: int32) =
      var ok: bool
      write_varint(self.buffer, value, ok)

method write_i64*(
   self: ref CompactProtocol;
   value: int64) =
      var ok: bool
      write_varint(self.buffer, value, ok)

method write_double*(
   self: ref CompactProtocol;
   value: float64) =
      # TODO this is meant to always be little endian
      # ... because of historical goofs by someone
      let mem = cast[array[8, byte])(value)
      for i in 0..7: self.buffer.add cast[char](mem[i])

method write_string*(
   self: ref CompactProtocol;
   value: string) =
      var ok: bool
      write_varint(self.buffer, value.len)
      self.buffer.add value

#/-
#| Read messages
#\-

method read_message_begin*(
   self: ref CompactProtocol;
   name: var string;
   kind: var TypeKind;
   sequence_number: var uint32) =
      var ok: bool
      var x = read_message_header(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      # TODO check protocol ID
      name = x.name
      kind = x.message_type
      sequence_number = x.sequence_id

method read_message_end*(
   self: ref CompactProtocol) =
      discard

method read_struct_begin*(
   self: ref CompactProtocol;
   name: var string) =
      self.last_id.add 0
      self.list_or_set.add false
      name = ""

method read_struct_end*(
   self: ref CompactProtocol) =
      if self.last_id.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.last_id.pop
      self.list_or_set.pop

method read_field_begin*(
   self: ref CompactProtocol;
   name: var string;
   kind: var TypeKind;
   id: var int) =
      var ok: bool
      var lid = self.last_field[self.last_field.high]
      var x = read_struct_field_header(self.buffer, lid, self.here, ok)
      self.last_field[self.last_field.high] = lid
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      id = x.field
      kind = x.kind
      name = ""

method read_field_end*(
   self: ref CompactProtocol) =
      discard

method read_map_begin*(
   self: ref CompactProtocol;
   key_kind, value_kind: var TypeKind;
   size: var int) =
      var ok: bool
      self.list_or_set.add true
      var x = read_map_header(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      key_kind = x.key_type
      value_kind = x.value_type
      size = x.map_elements

method read_map_end*(
   self: ref CompactProtocol) =
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.list_or_set.pop

method read_list_begin*(
   self: ref CompactProtocol;
   value_kind: var TypeKind;
   size: var int) =
      self.list_or_set.add true
      var ok: bool
      var x = read_list_header(self.buffer, selfhere, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
         # TODO

method read_list_end*(
   self: ref CompactProtocol) =
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.list_or_set.pop

method read_set_begin*(
   self: ref CompactProtocol;
   element_kind: var TypeKind;
   size: var int) =
      self.list_or_set.add true
      var ok: bool
      var x = read_list_header(self.buffer, selfhere, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
         # TODO

method read_set_end*(
   self: ref CompactProtocol) =
      if self.list_or_set.len == 0:
         # TODO exception
         raise new_exception("Stack underflow.")
      self.list_or_set.pop

method read_bool*(
   self: ref CompactProtocol;
   value: var bool) =
      if self.list_or_set[self.list_or_set.high]:
         # in a list, set, or map, so read one byte
         if self.here+1 in 0..self.buffer.high:
            value = (self[here] != 0)
            inc self.here
         else:
            # TODO
            raise new_exception(Exception, "Parsing failed.")
      else:
         # struct field; so read the type off the struct byte
         value = (self.buffer[self.here-1] and 0x0F) == 0x1

method read_byte*(
   self: ref CompactProtocol;
   value: var byte) =
      var ok: bool
      var x = read_varint(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      value = x.byte

method read_i16*(
   self: ref CompactProtocol;
   value: var int16) =
      var ok: bool
      var x = read_varint(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      value = x.int16

method read_i32*(
   self: ref CompactProtocol;
   value: var int32) =
      var ok: bool
      var x = read_varint(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      value = x.int32

method read_i64*(
   self: ref CompactProtocol;
   value: var int64) =
      var ok: bool
      var x = read_varint(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      value = x.int64

method read_double*(
   self: ref CompactProtocol;
   value: var float64) =
      # TODO this is meant to always be little endian
      # ... because of historical goofs by someone
      let mem = cast[array[8, byte])(value)
      if self.here+7 notin 0..self.buffer.high:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      for i in 0..7:
         mem[i] = self.buffer[self.here]
         inc self.here
      value = cast[float64](mem)

method read_string*(
   self: ref CompactProtocol;
   value: var string) =
      var ok: bool
      var strlen = read_varint(self.buffer, self.here, ok)
      if not ok:
         # TODO exception
         raise new_exception(Exception, "Parsing failed.")
      if strlen > 0:
         value = self.buffer.substr(self.here, self.here+(strlen-1))
      else:
         value = ""

