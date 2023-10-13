/* global ethers task */
module.exports = task('deploy-test-bookies', 'Deploys Bookies')
  .addFlag("test")
  .setAction(async (taskArgs) => {
    deploy_bookies = require("../scripts/deploy_bookies")
    await deploy_bookies(true, taskArgs.test);
  });