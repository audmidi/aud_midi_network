// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

// #############################################################################
/// Binds [count] UDP sockets on adjacent ports of [address], e.g. the
/// control and the data port of an AppleMIDI session.
///
/// - [firstPort] the first port, or 0 to let the system choose one and try
///   again when a neighbour port is taken.
/// - [attempts] how often to try with a port the system chose.
/// - [bind] binds one socket; tests replace it to provoke failures.
///
/// Throws the [SocketException] of the last failed attempt.
Future<List<RawDatagramSocket>> midiBindAdjacent({
  required InternetAddress address,
  required int count,
  int firstPort = 0,
  int attempts = 20,
  Future<RawDatagramSocket> Function(dynamic address, int port) bind =
      midiBindUdp,
}) async {
  assert(count > 0 && attempts > 0);
  late SocketException failure;
  for (var attempt = 0; attempt < attempts; attempt++) {
    final first = await bind(address, firstPort);
    final sockets = [first];
    try {
      for (var i = 1; i < count; i++) {
        sockets.add(await bind(address, first.port + i));
      }
      return sockets;
    } on SocketException catch (e) {
      failure = e;
      for (final socket in sockets) {
        socket.close();
      }
      if (firstPort != 0) {
        break;
      }
    }
  }
  throw failure;
}

// .............................................................................
/// Binds a UDP socket to [port] of [address] that no other socket of the
/// machine shares. [RawDatagramSocket.bind] sets SO_REUSEADDR, with which a
/// second socket on Windows takes over a port that is taken (ticket 38).
Future<RawDatagramSocket> midiBindUdp(dynamic address, int port) =>
    RawDatagramSocket.bind(address, port, reuseAddress: !Platform.isWindows);
