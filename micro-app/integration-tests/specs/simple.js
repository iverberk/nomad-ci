describe('the micro-app application', function() {
    it('should generate an introduction', function() {
        browser.url('/');
        browser.getText('#intro').should.match(/Hello, my name is .+ and I'm \d+ years old and I live in the .+ environment!/);
    });
});
