.pragma library

function validUrl(value) {
    return /^https:\/\/(?:www\.|m\.|music\.)?(?:youtube\.com|youtu\.be)\/[^\s]+$/i.test(String(value).trim());
}

function command(url, audio, quality, directory, format) {
    if (!validUrl(url)) return [];
    var args = ["yt-dlp", "--ignore-config", "--no-playlist", "--no-overwrites",
                "--newline", "--progress", "--no-colors", "--restrict-filenames",
                "--paths", directory, "-o", "%(title).160B [%(id)s].%(ext)s"];
    if (audio) {
        var audioFormat = ["mp3", "m4a", "opus", "flac", "wav"].indexOf(String(format).toLowerCase()) >= 0
            ? String(format).toLowerCase() : "mp3";
        args.push("-x", "--audio-format", audioFormat);
    }
    else {
        var height = String(quality).match(/^(360|480|720|1080|1440|2160)p?$/);
        height = height ? height[1] : "720";
        var container = ["mp4", "mkv", "webm"].indexOf(String(format).toLowerCase()) >= 0
            ? String(format).toLowerCase() : "mp4";
        args.push("-f", "bv*[height<=" + height + "]+ba/b[height<=" + height + "]", "--merge-output-format", container);
    }
    args.push("--", String(url).trim());
    return args;
}
