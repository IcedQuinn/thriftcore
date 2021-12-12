import protocol, theaderimpl

type
   THeaderProtocol* = ref object of Protocol
      header*: THeaderHeader ## Holds header for this particular reading.
      buffer*: string        ## Writes bytes to this buffer.
      wrapped*: Protocol     ## Other write calls are deferred to this.
      here*: int             ## Holds current position while reading.

const
   ENotImplemented = "Method not implemented."

#/-
#| Write messages
#\-

method write_message_begin*(self: THeaderProtocol; name: string; kind: MessageKind; sequence_number: int32) =
   var ok: bool
   write_theader(self.buffer, self.header, ok)
   if not ok:
      raise new_exception(Exception, "Writing failed.")
   write_message_begin(self.wrapped, name, kind, sequence_number)

method write_message_end*(self: THeaderProtocol) =
   write_message_end(self.wrapped) 

method write_struct_begin*(self: THeaderProtocol; name: string) =
   write_struct_begin(self.wrapped, name) 

method write_struct_end*(self: THeaderProtocol) =
   write_struct_end(self.wrapped)

method write_field_begin*(self: THeaderProtocol; name: string; kind: TypeKind; id: int) =
   write_field_begin(self.wrapped, name, kind, id) 

method write_field_end*(self: THeaderProtocol) =
   write_field_end(self.wrapped)

method write_field_stop*(self: THeaderProtocol) =
   write_field_stop(self.wrapped) 

method write_map_begin*(self: THeaderProtocol; key_kind,value_kind: TypeKind; size: int) =
   write_map_begin(self.wrapped, key_kind, value_kind, size) 

method write_map_end*(self: THeaderProtocol) =
   write_map_end(self.wrapped)

method write_list_begin*(self: THeaderProtocol; value_kind: TypeKind; size: int) =
   write_list_begin(self.wrapped, value_kind, size) 

method write_list_end*(self: THeaderProtocol) =
   write_list_end(self.wrapped)

method write_set_begin*(self: THeaderProtocol; element_kind: TypeKind; size: int) =
   write_set_begin(self.wrapped, element_kind, size) 

method write_set_end*(self: THeaderProtocol) =
   write_set_end(self.wrapped) 

method write_bool*(self: THeaderProtocol; value: bool) =
   write_bool(self.wrapped, value) 

method write_byte*(self: THeaderProtocol; value: byte) =
   write_byte(self.wrapped, value) 

method write_i16*(self: THeaderProtocol; value: int16) =
   write_i16(self.wrapped, value) 

method write_i32*(self: THeaderProtocol; value: int32) =
   write_i32(self.wrapped, value) 

method write_i64*(self: THeaderProtocol; value: int64) =
   write_i64(self.wrapped, value) 

method write_double*(self: THeaderProtocol; value: float64) =
   write_double(self.wrapped, value) 

method write_string*(self: THeaderProtocol; value: string) =
   write_string(self.wrapped, value) 

#/-
#| Read messages
#\-

method read_message_begin*(self: THeaderProtocol; name: var string; kind: var MessageKind; sequence_number: var int32) =
   var ok: bool
   self.header = read_theader(self.buffer, self.here, ok)
   if not ok:
      raise new_exception(Exception, "Reading failed.")
   read_message_begin(self.wrapped, name, kind, sequence_number)

method read_message_end*(self: THeaderProtocol) =
   read_message_end(self.wrapped)

method read_struct_begin*(self: THeaderProtocol; name: var string) =
   read_struct_begin(self.wrapped, name)

method read_struct_end*(self: THeaderProtocol) =
   read_struct_end(self.wrapped)

method read_field_begin*(self: THeaderProtocol; name: var string; kind: var TypeKind; id: var int) =
   read_field_begin(self.wrapped, name, kind, id)

method read_field_end*(self: THeaderProtocol) =
   read_field_end(self.wrapped)

method read_map_begin*(self: THeaderProtocol; key_kind, value_kind: var TypeKind; size: var int) =
   read_map_begin(self.wrapped, key_kind, value_kind, size)

method read_map_end*(self: THeaderProtocol) =
   read_map_end(self.wrapped)

method read_list_begin*(self: THeaderProtocol; value_kind: var TypeKind; size: var int) =
   read_list_begin(self.wrapped, value_kind, size)

method read_list_end*(self: THeaderProtocol) =
   read_list_end(self.wrapped)

method read_set_begin*(self: THeaderProtocol; element_kind: var TypeKind; size: var int) =
   read_set_begin(self.wrapped, element_kind, size)

method read_set_end*(self: THeaderProtocol) =
   read_set_end(self.wrapped)

method read_field_stop*(self: THeaderProtocol) =
   read_field_stop(self.wrapped)

method read_bool*(self: THeaderProtocol; value: var bool) =
   read_bool(self.wrapped, value)

method read_byte*(self: THeaderProtocol; value: var byte) =
   read_byte(self.wrapped, value)

method read_i16*(self: THeaderProtocol; value: var int16) =
   read_i16(self.wrapped, value)

method read_i32*(self: THeaderProtocol; value: var int32) =
   read_i32(self.wrapped, value)

method read_i64*(self: THeaderProtocol; value: var int64) =
   read_i64(self.wrapped, value)

method read_double*(self: THeaderProtocol; value: var float64) =
   read_double(self.wrapped, value)

method read_string*(self: THeaderProtocol; value: var string) =
   read_string(self.wrapped, value)

