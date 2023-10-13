/* global ethers task */
module.exports = task('get-bookie-info', 'Get bookie info')
  .addOptionalParam('bookie', 'Address of bookie', "", types.string)
  .setAction(async (taskArgs) => {
    get_bookie_info = require("../scripts/get_bookie_info")
    await get_bookie_info(taskArgs.bookie);
  });