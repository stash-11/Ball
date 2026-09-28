# My Utilities

A separate Omarchy plugin with a solid mint bubble tucked halfway beyond the top-right screen edge. Click its visible half to open it. It blinks and reacts to hovering and pressing. A small amber dot shows an active download when expanded.

Drag the collapsed bubble to reposition it. On release it snaps halfway into the nearest left, right, or bottom edge; the top edge is excluded. Both eyes stay on the visible half. A short click opens the widgets, while a drag only moves the bubble. The tab highlight slides between Music and YouTube without an outline.

Click the bubble to stretch it into the widget panel. Its outline ripples while growing, then gently settles; the eyes merge into one X. Music and YouTube tabs switch the single visible card inside. Click the X or press Escape to flow back into the bubble at the screen edge. One motion value drives the outline, eyes, contents and input region, on a fixed Wayland surface. It does not reserve screen space. You can also run:

```sh
omarchy-shell shell toggle io.github.stash-11.utilities '{}'
```

Music controls an existing MPRIS player (music apps and supported browsers). Use Player to cycle sources. Controls are disabled when unavailable.

Drop a YouTube link on the ball to open the YouTube tab with the URL filled in. Choose Video (360p through 2160p, with MP4, MKV, or WebM) or Music (MP3, M4A, Opus, FLAC, or WAV), then Download. Files go to your XDG Downloads directory; Files opens it. Existing files are not overwritten, playlists are disabled, and local yt-dlp configuration is ignored. The panel can close while its download continues; keepLoaded keeps the process alive. Shell reloads or logout may interrupt it; retrying the URL can resume partial downloads.

Dependencies: yt-dlp, ffmpeg, xdg-user-dir, xdg-open. A download needs network access. Status displays errors from yt-dlp. Video resolution and output container depend on the available formats. No downloads start until you press Download.

`Bubble.qml` owns the face and liquid outline, `Panel.qml` owns its motion and services, and `WidgetContent.qml` contains the widgets. The opaque GPU mask is `bubble-mask.frag`; its compiled shader is included. After changing the shader, rebuild it with `/usr/lib/qt6/bin/qsb --qt6 -o bubble-mask.frag.qsb bubble-mask.frag` from this folder.
