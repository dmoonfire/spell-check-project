module.exports = {
    instance: null,

    activate(state) {
        this.state = state;
    },

    serialize() {
        return this.state;
    },

    provideSpellCheck() {
        return require.resolve("./project-checker");
    },

    deactivate() {}
};
