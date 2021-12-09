proc read_u16be*(source: string; here: var int; ok: var bool): uint16 =
   ok = false
   let valid = 0..source.high
   var candy: array[2, byte]
   if here+3 notin valid: return
   for i in 0..1:
      candy[1-i] = cast[byte](source[here])
      inc here
   result = cast[uint16](candy)
   ok = true

proc read_u32be*(source: string; here: var int; ok: var bool): uint32 =
   ok = false
   let valid = 0..source.high
   var candy: array[4, byte]
   if here+3 notin valid: return
   for i in 0..3:
      candy[3-i] = cast[byte](source[here])
      inc here
   result = cast[uint32](candy)
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

