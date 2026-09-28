.pragma library

function validUrl(value) {
    return /^https:\/\/(?:www\.|m\.|music\.)?(?:youtube\.com|youtu\.be)\/[^\s]+$/i.test(String(value).trim());
}

function command(url, audio, quality, directory) {
    if (!validUrl(url)) return [];
    var args = ["yt-dlp", "--ignore-config", "--no-playlist", "--no-overwrites",
                "--newline", "--progress", "--no-colors", "--restrict-filenames",
                "--paths", directory, "-o", "%(title).160B [%(id)s].%(ext)s"];
    if (audio) args.push("-x", "--audio-format", "mp3");
    else {
        var height = ["480", "720", "1080"].indexOf(String(quality)) >= 0 ? String(quality) : "720";
        args.push("-f", "bv*[height<=" + height + "]+ba/b[height<=" + height + "]", "--merge-output-format", "mp4");
    }
    args.push("--", String(url).trim());
    return args;
}
