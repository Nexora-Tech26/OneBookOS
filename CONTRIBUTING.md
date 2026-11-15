# Contributing to OneBookOS

The project is experimental. Do not install prototype images over an existing Windows or Linux disk containing important data.

For a new task:
1. Branch from onebookui-rewrite into feature/stage-NN-description.
2. Keep one module or repair per PR. Add acceptance criteria and risk notes.
3. Keep legacy build/overlay/ and experimental onebookui/ unchanged unless a tested migration is specifically planned.
4. Run: python3 -m unittest discover -s tests -p test_foundation.py -v
5. For visual work, provide real running-build screenshots at an agreed display size; mockups do not count as screenshots.
6. For ISO/installer work, require the dedicated QEMU and virtual-disk gates.
7. Never call a source-check success a finished or stable operating system.

Project requirements are in docs/architecture, docs/design, docs/testing and docs/roadmap.
