
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

proc to_byte*(cet: CompactElementType): byte =
   case cet:
   of cetBoolTrue: return 2
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
   of 2: return cetBoolTrue
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

proc to_cmt*(cmt: CompactMessageType): byte =
   case cmt
   of 1: return cmtCall
   of 2: return cmtReply
   of 3: return cmtException
   of 4: return cmtOneway
   else:
      # XXX maybe throw a defect?
      return cmtUnknown

