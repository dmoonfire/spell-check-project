const debug = require('debug');

/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class ProjectChecker {
    static initClass() {
        this.prototype.projects = {};
        this.log = debug("spell-check-project");
    }

    constructor() {
        //console.log(@getId() + ": activing")
    }

    deactivate() {
        //console.log(getId() + ": deactivating")
    }

    getId() {
        return "spell-check-project";
    }

    getName() {
        return "Project Dictionary";
    }

    getPriority() {
        return 25;
    }

    isEnabled() {
        return true;
    }

    getStatus() {
        return "Working correctly.";
    }

    providesSpelling(args) {
        const project = this.getProject(args);

        if (!project || !project.valid) {
            false;
        }

        return true;
    }

    providesSuggestions(args) {
        const project = this.getProject(args);

        if (!project || !project.valid) {
            false;
        }

        return true;
    }

    providesAdding(args) {
        const project = this.getProject(args);

        if (!project || !project.valid) {
            false;
        }

        return true;
    }

    check(args, text) {
        // If we don't have language settings, we don't do anything.
        const project = this.getProject(args);

        if (!project || !project.valid) {
            return { id: this.getId() };
        }

        // Check the range for this dictionary.
        const ranges = [];
        const checked = project.checker.check(text);

        for (let token of Array.from(checked)) {
            if (token.status === 1) {
                ranges.push({ start: token.start, end: token.end });
            }
        }

        return { id: this.getId(), correct: ranges };
    }

    checkArray(args, words) {
        let word;
        const project = this.getProject(args);
        const results = [];

        if (!project || !project.valid) {
            // We don't have a project settings, so everything is unknown.
            for (word of Array.from(words)) {
                results.push(null);
            }
        } else {
            // We have a project, so check each one directly.
            for (let index = 0; index < words.length; index++) {
                word = words[index];
                const checked = project.checker.check(word);
                if (checked[0].status === 1) {
                    results.push(true);
                } else {
                    results.push(null);
                }
            }
        }

        // Return the results for the words, either all nulls or verified against the
        // project file.
        return results;
    }

    suggest(args, word) {
        // If we don't have language settings, we don't do anything.
        const project = this.getProject(args);

        if (!project || !project.valid) {
            return [];
        }

        // Pass the suggestion request to the project which provides it in the
        // desired format.
        const suggestions = project.spelling.suggest(word);

        if (!suggestions)
        {

        }

        return suggestions;
    }

    getAddingTargets(args) {
        return [{ sensitive: false, label: "Add to " + this.getName() }];
    }

    add(args, target) {
        // If we don't have language settings, then create a new one so
        // we can write it out.
        let project = this.getProject(args);

        if (!project || !project.valid) {
            // Add the word to the new spelling manager.
            const spellingManager = require("spelling-manager");
            project = { valid: true, json: {} };
            project.spelling = new spellingManager.TokenSpellingManager();

            // Clear out the cache since we'll be rebuilding it after
            // the @saveProject.
            delete this.projects[args.projectPath];
        }

        // Add it to the dictionary.
        project.spelling.add(target.word);
        return this.saveProject(args, project);
    }

    getProject(args) {
        // If there is no file, we can't find a project.
        let json, project;

        if (!args.projectPath) {
            return { valid: false, json: null };
        }

        // First see if we have the item already cached. If we do, then just use that.
        if (this.projects.hasOwnProperty(args.projectPath)) {
            project = this.projects[args.projectPath];
            return project;
        }

        // We don't have it cached, so load the `language.json` for this project root
        // so we can watch it.
        const path = require("path");
        const fs = require("fs");

        const languagePath = path.join(args.projectPath, "language.json");
        project = { valid: false, json: null };

        try {
            // See if the file doesn't exist. If it doesn't, then just cache and return
            // null value so we don't repeatedly try to load it again.
            const languageStat = fs.lstatSync(languagePath);

            if (languageStat && languageStat.isFile()) {
                // The file exists, so we need to load it into memory.
                console.log(this.getId() + ": loading " + languagePath);
                const jsonText = fs.readFileSync(languagePath);
                json = JSON.parse(jsonText);
                project = { valid: true, json };

                // Set up watching the file for changes.
                const that = this;
                project.watcher = fs.watch(
                    languagePath,
                    (ev, f) => delete that.projects[args.projectPath]
                );
            }
        } catch (err) {
            // lstatSync throws an exception, so just clear it out.
            project = { valid: false, json: null, error: err };
        }

        // Since we are creating it, we also need to set up the actual spelling. We do this
        // so (in theory) a project could then allow 'add to word' to be enabled for proejcts
        // that don't even have a file.
        const spellingManager = require("spelling-manager");
        project.spelling = new spellingManager.TokenSpellingManager();
        project.checker = new spellingManager.BufferSpellingChecker(
            project.spelling
        );

        // If we have a JSON and the known words, then add those words to the list.
        if (project.json && project.json.knownWords) {
            project.spelling.add(project.json.knownWords);
        }

        // Return the resulting project.
        this.projects[args.projectPath] = project;
        return project;
    }

    saveProject(args, project) {
        const path = require("path");
        const fs = require("fs");

        try {
            // Create a combined list of all the words so we can write them out.
            project.json.knownWords = project.spelling.list();

            // Figure out the path and save the file. The file watcher will cause this
            // to reload.
            const languagePath = path.join(args.projectPath, "language.json");
            const jsonText = JSON.stringify(project.json, null, "\t");
            return fs.writeFileSync(languagePath, jsonText);
        } catch (err) {
            return console.error(
                this.getId(),
                "Could not save project file:",
                err
            );
        }
    }
}

ProjectChecker.initClass();

const checker = new ProjectChecker();
module.exports = checker;
