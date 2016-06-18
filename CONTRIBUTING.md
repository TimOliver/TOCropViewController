# Contributing to `TOCropViewController`

Thanks so much for your interest in `TOCropViewController`! It makes me incredibly happy to hear that others have not just found it useful, but are eager to help contribute to it.

## Submitting a Pull Request
At this point, this library is pretty much a delicate house of cards. When modifying any of the code involved with the UI or layout, a lot of manual testing needs to be done to ensure that no regressions were introduced.

If you've added or changed a feature that directly involves any UI layout, please test the following to ensure nothing has broken.
* Presenting and dismissing the view controller in both portrait and landscape modes.
* Presenting the view controller, rotating the device and then dismissing from the new orientation.
* Presenting the view controller, then enabling split-screen on an iPad.
* Changing the split-screen window sizes on iPad.

If possible, please file an issue before filing a PR to discuss the feature you'd like to add. To ensure the quality of this view controller library doesn't dip, I plan to be very strict about the level of reliability and thoroughness of any code submitted through a PR. :)

## Submitting an Issue
I've included all of the essential tips for filing comprehensive issues directly in the [issues template](/TimOliver/TOCropViewController/blob/master/ISSUE_TEMPLATE.md). Please read that document and follow it as closely as you can when filing new issues.

---

Thanks again for your interest in `TOCropViewController`! I hope you've found the library useful in your apps!
