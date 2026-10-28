import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _folders = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    final folderId = controller.openFolderId;
    final lines = folderId == null
        ? controller.saved
        : controller.saved.where((line) => line.folderId == folderId).toList();
    final showFolders = folderId == null && _folders;

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            if (folderId == null)
              const BloomHeader(title: 'Saved')
            else
              BloomHeader(
                title: lineFolders.firstWhere((folder) => folder.id == folderId).name,
                back: true,
                onBack: () => controller.openFolder(null),
              ),
            if (folderId == null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SavedSwitch(
                  folders: _folders,
                  onChanged: (value) => setState(() => _folders = value),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: showFolders
                  ? _FolderList(saved: controller.saved)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        if (lines.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Text(
                              'Saved lines will gather here.',
                              textAlign: TextAlign.center,
                              style: BloomType.sans(size: 14, color: Bloom.inkSoft),
                            ),
                          )
                        else
                          for (final line in lines) _SavedCard(line: line),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSwitch extends StatelessWidget {
  const _SavedSwitch({required this.folders, required this.onChanged});

  final bool folders;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Bloom.bgDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Lines',
            selected: !folders,
            onTap: () => onChanged(false),
          ),
          _Segment(
            label: 'Folders',
            selected: folders,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? const [
                    BoxShadow(color: Bloom.shadow, blurRadius: 8, offset: Offset(0, 2)),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: BloomType.sans(
              size: 14,
              weight: FontWeight.w700,
              color: selected ? Bloom.ink : Bloom.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderList extends StatelessWidget {
  const _FolderList({required this.saved});

  final List<SavedLine> saved;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        for (final folder in lineFolders)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.read<DesignController>().openFolder(folder.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Bloom.shadow, blurRadius: 18, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Bloom.pinkSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.folder_rounded, color: Bloom.pink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folder.name,
                              style: BloomType.sans(size: 15, weight: FontWeight.w800),
                            ),
                            Text(
                              folder.detail,
                              style: BloomType.sans(size: 12.5, color: Bloom.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${saved.where((line) => line.folderId == folder.id).length}',
                        style: BloomType.sans(
                          size: 14,
                          weight: FontWeight.w800,
                          color: Bloom.pink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.line});

  final SavedLine line;

  @override
  Widget build(BuildContext context) {
    final style = toneStyle(line.tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: line.text));
            if (context.mounted) showBloomSnack(context, 'Copied');
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Bloom.shadow, blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoFrame(asset: line.image, width: 72, height: 72, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: BloomType.sans(
                          size: 13.5,
                          weight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(label: line.tag, filled: false, color: Bloom.inkSoft),
                          _Tag(
                            label: line.mood,
                            filled: true,
                            color: style.fg,
                            bg: style.bg,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<DesignController>().removeSaved(line.id),
                  icon: const Icon(Icons.favorite_rounded, color: Bloom.pink, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.filled,
    required this.color,
    this.bg,
  });

  final String label;
  final bool filled;
  final Color color;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? (bg ?? Bloom.pinkSoft) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: Bloom.line),
      ),
      child: Text(
        label,
        style: BloomType.sans(
          size: 11,
          weight: FontWeight.w700,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}
