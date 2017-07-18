---
layout: documentation
title: FAQ
permalink: documentation/faq.html
---

{: .lead}
Random collection of all the things we've ever been asked.

<br />

#### Why can't I run android-runner on a mac?

You can, but we don't recommend it. We've found ADB to be less stable on the mac
than it is on linux. It's certainly good enough for day-to-day dev use but when
you have multiple devices all plugged in, hamering adb, some weird issues creep
in.

<hr />

#### Why aren't my screenshots getting uploaded to the Scheduler?

You need to make sure that any assets you want uploading to the Scheduler are
written to (or copied to) the results directory for the job. The $HIVE_RESULTS
environment variable exposes this path for your tests.
