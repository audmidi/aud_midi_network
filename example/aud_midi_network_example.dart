// @license
// Copyright (c) Audanika
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore_for_file: avoid_print

import 'package:aud_midi_core/aud_midi_core.dart';
import 'package:aud_midi_network/aud_midi_network.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';

Future<void> main() async {
  // Two AppleMIDI sessions on this machine; the system picks the ports
  final studio = MidiAppleMidiSession(localName: 'Studio', requestedPort: 0);
  final stage = MidiAppleMidiSession(localName: 'Stage', requestedPort: 0);
  await studio.open();
  await stage.open();
  final received = studio.received.first;

  // The stage invites the studio and plays a note once it is connected
  final connection = await stage.connect(
    MidiNetworkHostInfo(
      name: studio.localName,
      address: '127.0.0.1',
      port: studio.port,
    ),
  );
  print('${connection.remoteName}: ${connection.state.name}');
  const clock = MidiSystemClock();
  await connection.send(
    MidiBytesPacket(bytes: MidiBytes([0x90, 60, 100]), time: clock.now()),
  );

  // The studio receives it over RTP-MIDI
  final (connection: from, :packet) = await received;
  print('${from.remoteName} sent $packet');

  await stage.close();
  await studio.close();
}
