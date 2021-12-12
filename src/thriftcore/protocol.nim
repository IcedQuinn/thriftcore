
type
   TypeKind* = enum
      tkUnknown
      tkI16
      tkI32
      tkI64
      tkStruct
      tkMap
      tkList
      tkSet
      tkBool
      tkByte
      tkDouble
      tkString

   MessageKind* = enum
      mkCall
      mkReply
      mkException
      mkOneway

   Protocol* = ref object of RootObj

const
   ENotImplemented = "Method not implemented."

#/-
#| Write messages
#\-

method write_message_begin*(self: Protocol; name: string; kind: MessageKind; sequence_number: int32)            {.base.} = raise new_exception(Defect, ENotImplemented)
method write_message_end*  (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_struct_begin* (self: Protocol; name: string)                                                       {.base.} = raise new_exception(Defect, ENotImplemented)
method write_struct_end*   (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_field_begin*  (self: Protocol; name: string; kind: TypeKind; id: int)                              {.base.} = raise new_exception(Defect, ENotImplemented)
method write_field_end*    (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_field_stop*   (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_map_begin*    (self: Protocol; key_kind, value_kind: TypeKind; size: int)                          {.base.} = raise new_exception(Defect, ENotImplemented)
method write_map_end*      (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_list_begin*   (self: Protocol; value_kind: TypeKind; size: int)                                    {.base.} = raise new_exception(Defect, ENotImplemented)
method write_list_end*     (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_set_begin*    (self: Protocol; element_kind: TypeKind; size: int)                                  {.base.} = raise new_exception(Defect, ENotImplemented)
method write_set_end*      (self: Protocol)                                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_bool*         (self: Protocol; value: bool)                                                        {.base.} = raise new_exception(Defect, ENotImplemented)
method write_byte*         (self: Protocol; value: byte)                                                        {.base.} = raise new_exception(Defect, ENotImplemented)
method write_i16*          (self: Protocol; value: int16)                                                       {.base.} = raise new_exception(Defect, ENotImplemented)
method write_i32*          (self: Protocol; value: int32)                                                       {.base.} = raise new_exception(Defect, ENotImplemented)
method write_i64*          (self: Protocol; value: int64)                                                       {.base.} = raise new_exception(Defect, ENotImplemented)
method write_double*       (self: Protocol; value: float64)                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method write_string*       (self: Protocol; value: string)                                                      {.base.} = raise new_exception(Defect, ENotImplemented)

#/-
#| Read messages
#\-

method read_message_begin*(self: Protocol; name: var string; kind: var MessageKind; sequence_number: var int32) {.base.} = raise new_exception(Defect, ENotImplemented)
method read_message_end*  (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_struct_begin* (self: Protocol; name: var string)                                                    {.base.} = raise new_exception(Defect, ENotImplemented)
method read_struct_end*   (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_field_begin*  (self: Protocol; name: var string; kind: var TypeKind, id: var int)                   {.base.} = raise new_exception(Defect, ENotImplemented)
method read_field_end*    (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_map_begin*    (self: Protocol; key_kind, value_kind: var TypeKind; size: var int)                   {.base.} = raise new_exception(Defect, ENotImplemented)
method read_map_end*      (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_list_begin*   (self: Protocol; value_kind: var TypeKind; size: var int)                             {.base.} = raise new_exception(Defect, ENotImplemented)
method read_list_end*     (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_set_begin*    (self: Protocol; element_kind: var TypeKind; size: var int)                           {.base.} = raise new_exception(Defect, ENotImplemented)
method read_set_end*      (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_field_stop*   (self: Protocol)                                                                      {.base.} = raise new_exception(Defect, ENotImplemented)
method read_bool*         (self: Protocol; value: var bool)                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method read_byte*         (self: Protocol; value: var byte)                                                     {.base.} = raise new_exception(Defect, ENotImplemented)
method read_i16*          (self: Protocol; value: var int16)                                                    {.base.} = raise new_exception(Defect, ENotImplemented)
method read_i32*          (self: Protocol; value: var int32)                                                    {.base.} = raise new_exception(Defect, ENotImplemented)
method read_i64*          (self: Protocol; value: var int64)                                                    {.base.} = raise new_exception(Defect, ENotImplemented)
method read_double*       (self: Protocol; value: var float64)                                                  {.base.} = raise new_exception(Defect, ENotImplemented)
method read_string*       (self: Protocol; value: var string)                                                   {.base.} = raise new_exception(Defect, ENotImplemented)

