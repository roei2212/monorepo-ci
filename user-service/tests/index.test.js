const { helloUser } = require("../src/index");

test("returns greeting", () => {
  expect(helloUser()).toBe("Hello from user-service");
});
