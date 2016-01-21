console.log "editor", @editor
console.log "file", @editor.buffer.file.path
console.log "path", atom.project.relativizePath(@editor.buffer.file.path)
