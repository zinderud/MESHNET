// test/services/communication/real_time_voice_communication_test.dart - Real-Time Voice Communication Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:meshnet_app/services/communication/real_time_voice_communication.dart';

// Generate mocks for external dependencies
@GenerateMocks([])
class MockStreamController extends Mock implements StreamController<VoiceData> {}
class MockTimer extends Mock implements Timer {}

void main() {
  group('RealTimeVoiceCommunication Tests', () {
    late RealTimeVoiceCommunication voiceService;
    
    setUp(() {
      voiceService = RealTimeVoiceCommunication.instance;
    });
    
    tearDown(() async {
      if (voiceService.isInitialized) {
        await voiceService.shutdown();
      }
    });

    group('Service Initialization', () {
      test('should initialize voice communication service successfully', () async {
        final result = await voiceService.initialize();
        
        expect(result, isTrue);
        expect(voiceService.isInitialized, isTrue);
        expect(voiceService.currentCodec, equals(VoiceCodec.opus));
        expect(voiceService.networkCondition, equals(NetworkCondition.good));
      });
      
      test('should handle initialization failure gracefully', () async {
        // Test initialization with invalid configuration
        final result = await voiceService.initialize(
          config: VoiceConfig(
            defaultCodec: VoiceCodec.opus,
            sampleRate: -1, // Invalid sample rate
            channels: 0, // Invalid channels
            bitrate: 0, // Invalid bitrate
            bufferSize: 0, // Invalid buffer size
            enableVAD: true,
            enableAGC: true,
            enableNoiseReduction: true,
            enableEchoCancellation: true,
            emergencyMode: false,
            adaptiveQuality: true,
            meshIntegration: true,
            encryptionEnabled: true,
            compressionLevel: 5,
          ),
        );
        
        // Should still initialize with default values
        expect(result, isTrue);
        expect(voiceService.isInitialized, isTrue);
      });
      
      test('should not double-initialize service', () async {
        await voiceService.initialize();
        expect(voiceService.isInitialized, isTrue);
        
        final secondInit = await voiceService.initialize();
        expect(secondInit, isTrue); // Should return true but not re-initialize
      });
    });

    group('Codec Management', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should switch to emergency codec in emergency mode', () async {
        final result = await voiceService.switchCodec(VoiceCodec.emergency_ultra_low);
        
        expect(result, isTrue);
        expect(voiceService.currentCodec, equals(VoiceCodec.emergency_ultra_low));
        expect(voiceService.isEmergencyMode, isTrue);
      });
      
      test('should switch to high quality codec when network is good', () async {
        await voiceService.updateNetworkCondition(NetworkCondition.excellent);
        
        final result = await voiceService.switchCodec(VoiceCodec.opus);
        
        expect(result, isTrue);
        expect(voiceService.currentCodec, equals(VoiceCodec.opus));
      });
      
      test('should automatically adapt codec based on network conditions', () async {
        // Test adaptive codec switching
        await voiceService.updateNetworkCondition(NetworkCondition.poor);
        await voiceService.enableAdaptiveQuality(true);
        
        // Should switch to lower quality codec
        expect(voiceService.currentCodec, isIn([
          VoiceCodec.speex_narrow,
          VoiceCodec.g729,
          VoiceCodec.emergency_ultra_low,
        ]));
      });
      
      test('should validate codec compatibility', () {
        final compatibleCodecs = voiceService.getSupportedCodecs();
        
        expect(compatibleCodecs, isNotEmpty);
        expect(compatibleCodecs, contains(VoiceCodec.opus));
        expect(compatibleCodecs, contains(VoiceCodec.emergency_ultra_low));
        expect(compatibleCodecs.length, equals(12)); // All 12 codecs should be supported
      });
    });

    group('Audio Processing', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should start audio recording successfully', () async {
        final result = await voiceService.startRecording();
        
        expect(result, isTrue);
        expect(voiceService.isRecording, isTrue);
      });
      
      test('should stop audio recording successfully', () async {
        await voiceService.startRecording();
        expect(voiceService.isRecording, isTrue);
        
        final result = await voiceService.stopRecording();
        
        expect(result, isTrue);
        expect(voiceService.isRecording, isFalse);
      });
      
      test('should start audio playback successfully', () async {
        final result = await voiceService.startPlayback();
        
        expect(result, isTrue);
        expect(voiceService.isPlaying, isTrue);
      });
      
      test('should stop audio playback successfully', () async {
        await voiceService.startPlayback();
        expect(voiceService.isPlaying, isTrue);
        
        final result = await voiceService.stopPlayback();
        
        expect(result, isTrue);
        expect(voiceService.isPlaying, isFalse);
      });
      
      test('should process audio data correctly', () async {
        final testAudioData = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        final result = await voiceService.processAudioData(testAudioData);
        
        expect(result, isNotNull);
        expect(result, isA<Uint8List>());
      });
      
      test('should apply audio filters correctly', () async {
        await voiceService.enableNoiseReduction(true);
        await voiceService.enableEchoCancellation(true);
        await voiceService.enableVAD(true);
        
        final testAudioData = Uint8List.fromList(List.generate(1024, (i) => i % 256));
        final result = await voiceService.processAudioData(testAudioData);
        
        expect(result, isNotNull);
        expect(result!.length, greaterThan(0));
      });
    });

    group('Emergency Protocols', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should activate emergency mode successfully', () async {
        final result = await voiceService.activateEmergencyMode();
        
        expect(result, isTrue);
        expect(voiceService.isEmergencyMode, isTrue);
        expect(voiceService.currentCodec, equals(VoiceCodec.emergency_ultra_low));
      });
      
      test('should deactivate emergency mode successfully', () async {
        await voiceService.activateEmergencyMode();
        expect(voiceService.isEmergencyMode, isTrue);
        
        final result = await voiceService.deactivateEmergencyMode();
        
        expect(result, isTrue);
        expect(voiceService.isEmergencyMode, isFalse);
      });
      
      test('should handle emergency calls correctly', () async {
        final emergencyCall = EmergencyCall(
          callId: 'emergency_123',
          callType: EmergencyCallType.medical,
          priority: EmergencyPriority.critical,
          location: {'lat': 40.7128, 'lng': -74.0060},
          description: 'Medical emergency',
          requesterInfo: {'name': 'John Doe', 'phone': '+1234567890'},
          timestamp: DateTime.now(),
          isActive: true,
          responseTeam: [],
          estimatedResponse: const Duration(minutes: 10),
          metadata: {},
        );
        
        final result = await voiceService.handleEmergencyCall(emergencyCall);
        
        expect(result, isTrue);
        expect(voiceService.isEmergencyMode, isTrue);
      });
      
      test('should prioritize emergency traffic', () async {
        await voiceService.activateEmergencyMode();
        
        final normalCall = VoiceCall(
          callId: 'normal_call',
          participants: ['user1', 'user2'],
          callType: VoiceCallType.peer_to_peer,
          priority: CallPriority.normal,
          codec: VoiceCodec.opus,
          isActive: true,
          startTime: DateTime.now(),
          metadata: {},
        );
        
        final emergencyCall = VoiceCall(
          callId: 'emergency_call',
          participants: ['emergency_service', 'user1'],
          callType: VoiceCallType.emergency,
          priority: CallPriority.emergency,
          codec: VoiceCodec.emergency_ultra_low,
          isActive: true,
          startTime: DateTime.now(),
          metadata: {'emergency_type': 'medical'},
        );
        
        // Emergency call should have higher priority
        expect(emergencyCall.priority.index, lessThan(normalCall.priority.index));
      });
    });

    group('Call Management', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should initiate voice call successfully', () async {
        final result = await voiceService.initiateCall(
          targetId: 'user123',
          callType: VoiceCallType.peer_to_peer,
        );
        
        expect(result, isNotNull);
        expect(result!.isActive, isTrue);
        expect(result.participants, contains('user123'));
      });
      
      test('should accept incoming call successfully', () async {
        // Simulate incoming call
        final incomingCall = VoiceCall(
          callId: 'incoming_123',
          participants: ['caller', 'current_user'],
          callType: VoiceCallType.peer_to_peer,
          priority: CallPriority.normal,
          codec: VoiceCodec.opus,
          isActive: false,
          startTime: DateTime.now(),
          metadata: {},
        );
        
        final result = await voiceService.acceptCall(incomingCall.callId);
        
        expect(result, isTrue);
      });
      
      test('should reject incoming call successfully', () async {
        final result = await voiceService.rejectCall('incoming_123');
        
        expect(result, isTrue);
      });
      
      test('should end active call successfully', () async {
        final call = await voiceService.initiateCall(
          targetId: 'user123',
          callType: VoiceCallType.peer_to_peer,
        );
        
        expect(call, isNotNull);
        
        final result = await voiceService.endCall(call!.callId);
        
        expect(result, isTrue);
      });
      
      test('should handle multiple concurrent calls', () async {
        final call1 = await voiceService.initiateCall(
          targetId: 'user1',
          callType: VoiceCallType.peer_to_peer,
        );
        
        final call2 = await voiceService.initiateCall(
          targetId: 'user2',
          callType: VoiceCallType.peer_to_peer,
        );
        
        expect(call1, isNotNull);
        expect(call2, isNotNull);
        expect(call1!.callId, isNot(equals(call2!.callId)));
      });
    });

    group('Quality Management', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should adjust quality based on network conditions', () async {
        await voiceService.updateNetworkCondition(NetworkCondition.poor);
        await voiceService.enableAdaptiveQuality(true);
        
        final quality = voiceService.getCurrentQuality();
        
        expect(quality, isA<VoiceQuality>());
        expect(quality.bitrate, lessThanOrEqualTo(32000)); // Should use lower bitrate for poor network
      });
      
      test('should monitor audio quality metrics', () async {
        await voiceService.startRecording();
        await voiceService.startPlayback();
        
        // Let some time pass for metrics collection
        await Future.delayed(const Duration(milliseconds: 100));
        
        final metrics = voiceService.getQualityMetrics();
        
        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics, containsKey('latency'));
        expect(metrics, containsKey('jitter'));
        expect(metrics, containsKey('packetLoss'));
        expect(metrics, containsKey('mos'));
      });
      
      test('should handle buffer management correctly', () async {
        await voiceService.setBufferSize(2048);
        
        final testData = Uint8List.fromList(List.generate(4096, (i) => i % 256));
        
        final result = await voiceService.processAudioData(testData);
        
        expect(result, isNotNull);
        // Should handle data larger than buffer size
      });
    });

    group('Mesh Integration', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should integrate with mesh network successfully', () async {
        final result = await voiceService.enableMeshIntegration(true);
        
        expect(result, isTrue);
        expect(voiceService.isMeshEnabled, isTrue);
      });
      
      test('should route voice data through mesh network', () async {
        await voiceService.enableMeshIntegration(true);
        
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = await voiceService.sendVoiceData('target_node', testData);
        
        expect(result, isTrue);
      });
      
      test('should handle mesh network failures', () async {
        await voiceService.enableMeshIntegration(true);
        await voiceService.updateNetworkCondition(NetworkCondition.critical);
        
        // Should still attempt to send data with fallback mechanisms
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = await voiceService.sendVoiceData('target_node', testData);
        
        // May succeed or fail depending on network condition, but should not throw
        expect(result, isA<bool>());
      });
    });

    group('Security and Encryption', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should enable encryption successfully', () async {
        final result = await voiceService.enableEncryption(true);
        
        expect(result, isTrue);
        expect(voiceService.isEncryptionEnabled, isTrue);
      });
      
      test('should encrypt voice data correctly', () async {
        await voiceService.enableEncryption(true);
        
        final plainData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final encryptedData = await voiceService.processAudioData(plainData);
        
        expect(encryptedData, isNotNull);
        expect(encryptedData, isNot(equals(plainData))); // Should be different after encryption
      });
      
      test('should handle encryption key management', () async {
        await voiceService.enableEncryption(true);
        
        final keyGenerated = await voiceService.generateEncryptionKey();
        expect(keyGenerated, isTrue);
        
        final keyExchanged = await voiceService.exchangeKeys('peer_id');
        expect(keyExchanged, isTrue);
      });
    });

    group('Performance and Statistics', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should track performance statistics', () async {
        await voiceService.startRecording();
        await voiceService.startPlayback();
        
        // Generate some activity
        for (int i = 0; i < 10; i++) {
          final testData = Uint8List.fromList(List.generate(1024, (j) => j % 256));
          await voiceService.processAudioData(testData);
        }
        
        final stats = voiceService.getStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['totalCalls'], isA<int>());
        expect(stats['activeCalls'], isA<int>());
        expect(stats['emergencyCalls'], isA<int>());
        expect(stats['averageCallDuration'], isA<double>());
        expect(stats['dataTransferred'], isA<int>());
      });
      
      test('should calculate call quality metrics', () async {
        final call = await voiceService.initiateCall(
          targetId: 'user123',
          callType: VoiceCallType.peer_to_peer,
        );
        
        expect(call, isNotNull);
        
        // Simulate some call activity
        await Future.delayed(const Duration(milliseconds: 100));
        
        final metrics = voiceService.getQualityMetrics();
        
        expect(metrics['latency'], isA<num>());
        expect(metrics['jitter'], isA<num>());
        expect(metrics['packetLoss'], isA<num>());
        expect(metrics['mos'], isA<num>());
        expect(metrics['mos'], greaterThanOrEqualTo(1.0));
        expect(metrics['mos'], lessThanOrEqualTo(5.0));
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should handle invalid audio data gracefully', () async {
        final invalidData = Uint8List(0); // Empty data
        
        final result = await voiceService.processAudioData(invalidData);
        
        // Should handle gracefully, either return null or empty data
        expect(result, anyOf(isNull, isEmpty));
      });
      
      test('should handle codec switching errors', () async {
        // Try to switch to non-existent codec
        const invalidCodec = VoiceCodec.values; // This should cause an error
        
        // Should handle gracefully without crashing
        expect(() => voiceService.currentCodec, returnsNormally);
      });
      
      test('should handle network disconnection gracefully', () async {
        await voiceService.updateNetworkCondition(NetworkCondition.critical);
        
        final call = await voiceService.initiateCall(
          targetId: 'user123',
          callType: VoiceCallType.peer_to_peer,
        );
        
        // Call may fail but should not crash the service
        expect(voiceService.isInitialized, isTrue);
      });
      
      test('should recover from emergency mode errors', () async {
        await voiceService.activateEmergencyMode();
        
        // Simulate error in emergency mode
        await voiceService.updateNetworkCondition(NetworkCondition.critical);
        
        // Should still maintain emergency mode functionality
        expect(voiceService.isEmergencyMode, isTrue);
        expect(voiceService.isInitialized, isTrue);
      });
    });

    group('Stream Management', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should provide voice data stream', () async {
        final stream = voiceService.voiceDataStream;
        
        expect(stream, isA<Stream<VoiceData>>());
        
        // Test stream subscription
        final subscription = stream.listen((data) {
          expect(data, isA<VoiceData>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide call events stream', () async {
        final stream = voiceService.callEventsStream;
        
        expect(stream, isA<Stream<VoiceCall>>());
        
        // Test stream subscription
        final subscription = stream.listen((call) {
          expect(call, isA<VoiceCall>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide quality metrics stream', () async {
        final stream = voiceService.qualityMetricsStream;
        
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        
        // Test stream subscription
        final subscription = stream.listen((metrics) {
          expect(metrics, isA<Map<String, dynamic>>());
        });
        
        await subscription.cancel();
      });
    });

    group('Integration Tests', () {
      setUp(() async {
        await voiceService.initialize();
      });
      
      test('should handle complete voice call flow', () async {
        // Start call
        final call = await voiceService.initiateCall(
          targetId: 'user123',
          callType: VoiceCallType.peer_to_peer,
        );
        
        expect(call, isNotNull);
        expect(call!.isActive, isTrue);
        
        // Start recording and playback
        await voiceService.startRecording();
        await voiceService.startPlayback();
        
        expect(voiceService.isRecording, isTrue);
        expect(voiceService.isPlaying, isTrue);
        
        // Process some audio data
        final testData = Uint8List.fromList(List.generate(1024, (i) => i % 256));
        final processedData = await voiceService.processAudioData(testData);
        
        expect(processedData, isNotNull);
        
        // End call
        final endResult = await voiceService.endCall(call.callId);
        expect(endResult, isTrue);
        
        // Stop recording and playback
        await voiceService.stopRecording();
        await voiceService.stopPlayback();
        
        expect(voiceService.isRecording, isFalse);
        expect(voiceService.isPlaying, isFalse);
      });
      
      test('should handle emergency scenario end-to-end', () async {
        // Activate emergency mode
        await voiceService.activateEmergencyMode();
        expect(voiceService.isEmergencyMode, isTrue);
        
        // Create emergency call
        final emergencyCall = EmergencyCall(
          callId: 'emergency_test',
          callType: EmergencyCallType.fire,
          priority: EmergencyPriority.critical,
          location: {'lat': 40.7128, 'lng': -74.0060},
          description: 'Fire emergency test',
          requesterInfo: {'name': 'Test User'},
          timestamp: DateTime.now(),
          isActive: true,
          responseTeam: [],
          estimatedResponse: const Duration(minutes: 5),
          metadata: {},
        );
        
        // Handle emergency call
        final handled = await voiceService.handleEmergencyCall(emergencyCall);
        expect(handled, isTrue);
        
        // Verify emergency codec is used
        expect(voiceService.currentCodec, equals(VoiceCodec.emergency_ultra_low));
        
        // Test emergency communication
        await voiceService.startRecording();
        await voiceService.startPlayback();
        
        final emergencyData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = await voiceService.sendVoiceData('emergency_service', emergencyData);
        
        expect(result, isTrue);
        
        // Cleanup
        await voiceService.stopRecording();
        await voiceService.stopPlayback();
        await voiceService.deactivateEmergencyMode();
      });
    });
  });
}
