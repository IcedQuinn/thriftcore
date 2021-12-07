# Encoding interface
## Write messages
- write_message_begin(name,type,seq)
- write_message_end()
- write_struct_begin(name)
- write_struct_end()
- write_field_begin(name,type,id)
- write_field_end()
- write_field_stop()
- write_map_begin(name,ktype,vtype,size)
- write_map_end()
- write_list_begin(name,vtype,size)
- write_list_end()
- write_set_begin(etype,size)
- write_set_end()
- write_bool(bool)
- write_byte(byte)
- write_i8(i8)
- write_i16(i16)
- write_i32(i32)
- write_i64(i64)
- write_double(double)
- write_string(string)

## Read messages
- (name,type,seq)   = read_message_begin()
- ()                = read_message_end()
- (name)            = read_struct_begin()
- ()                = read_struct_end()
- (name,type,id)    = read_field_begin()
- ()                = read_field_end()
- ()                = read_field_stop()
- (name,ktype,vtype,size) = read_map_begin()
- (                 = read_map_end()
- (etype,size)      = read_list_begin()
- ()                = read_list_end()
- (etype,size)      = read_set_begin()
- ()                = read_set_end()
- (bool)            = read_bool()
- (byte)            = read_byte()
- (i8)              = read_i8()
- (i16)             = read_i16()
- (i32)             = read_i32()
- (i64)             = read_i64()
- (double)          = read_double()
- (string)          = read_string()

# Transport interface
- open
- close
- is_open
- read
- write
- flush

# Server transport interface
- open
- listen
- accept
- close

