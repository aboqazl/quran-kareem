import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_scope.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<PlayerState>(
      stream: app.audio.player.playerStateStream,
      builder: (context, stateSnap) {
        final state = stateSnap.data;
        final active = state != null && (state.playing || state.processingState != ProcessingState.idle);
        if (!active) return const SizedBox.shrink();
        return Material(
          elevation: 3,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(children: [
                const Icon(Icons.graphic_eq, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: StreamBuilder<SequenceState?>(
                    stream: app.audio.player.sequenceStateStream,
                    builder: (_, snap) {
                      final tag = snap.data?.currentSource?.tag;
                      final title = tag is MediaItem ? tag.title : 'تلاوة القرآن';
                      return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge);
                    },
                  ),
                ),
                IconButton(tooltip: 'السابق', visualDensity: VisualDensity.compact, onPressed: app.audio.player.seekToPrevious, icon: const Icon(Icons.skip_previous)),
                IconButton(
                  tooltip: state.playing ? 'إيقاف مؤقت' : 'تشغيل',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => state.playing ? app.audio.player.pause() : app.audio.player.play(),
                  icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(tooltip: 'التالي', visualDensity: VisualDensity.compact, onPressed: app.audio.player.seekToNext, icon: const Icon(Icons.skip_next)),
                StreamBuilder<double>(
                  stream: app.audio.player.speedStream,
                  builder: (_, snap) => PopupMenuButton<double>(
                    tooltip: 'سرعة التلاوة',
                    initialValue: snap.data ?? 1.0,
                    onSelected: app.audio.player.setSpeed,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: .75, child: Text('0.75×')),
                      PopupMenuItem(value: 1.0, child: Text('1×')),
                      PopupMenuItem(value: 1.25, child: Text('1.25×')),
                    ],
                    child: Padding(padding: const EdgeInsets.all(8), child: Text('${(snap.data ?? 1.0).toStringAsFixed(2)}×', style: Theme.of(context).textTheme.labelSmall)),
                  ),
                ),
                IconButton(tooltip: 'إيقاف', visualDensity: VisualDensity.compact, onPressed: app.audio.stop, icon: const Icon(Icons.close)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
