# TODO maybe treat each .nim as a file group so their individual dependencies are propagated
# TODO use a template instead of raw gentest

gentest(
   name='theader',
   cmd=['nim c src/thriftcore/theader'],
   test_cmd=['./src/thriftcore/theader'],
   outs=['./src/thriftcore/theader'],
   no_test_output=True,
   srcs=[
      'src/thriftcore/theader.nim',
      'src/thriftcore/protocol.nim',
      'src/thriftcore/theaderimpl.nim',
      'src/thriftcore/varint.nim',
      'src/thriftcore/codecutil.nim',
   ],
)

gentest(
   name='tcompact',
   cmd=['nim c src/thriftcore/tcompact'],
   test_cmd=['./src/thriftcore/tcompact'],
   outs=['./src/thriftcore/tcompact'],
   no_test_output=True,
   srcs=[
      'src/thriftcore/tcompact.nim',
      'src/thriftcore/tcompactimpl.nim',
      'src/thriftcore/protocol.nim',
      'src/thriftcore/varint.nim',
      'src/thriftcore/codecutil.nim',
   ],
)

