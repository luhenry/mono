using System;
using System.Threading;

/*
This test stresses what happens when root domain threads are allocating into the nursery
while a domain is cleaned up.

This is a regression test for a crash in the domain object cleaner code that did not
stop-the-world before walking the heap.
*/
class Driver {
	static void AllocStuff ()
	{
		var x = new object ();
		for (int i = 0; i < 300; ++i)
			x = new byte [i];
	}

	static void BackgroundNoise ()
	{
		while (true)
			AllocStuff ();
	}

	static void Main () {
		for (int i = 0; i < Math.Max (1, Environment.ProcessorCount / 2); ++i) {
		// for (int i = 0; i < 4; ++i) {
			var t = new Thread (BackgroundNoise);
			t.IsBackground = true;
			t.Start ();
		}

		TestTimeout.RepeatFor (TestTimeout.Stress ? 600 : 5, delegate (int i) {
			var ad = AppDomain.CreateDomain ("domain_" + i);
			ad.DoCallBack (new CrossAppDomainDelegate (AllocStuff));
			AppDomain.Unload (ad);

			Console.Write (".");
			if (i > 0 && i % 20 == 0) Console.WriteLine ();
		});

		Console.WriteLine ("\ndone");
	}
}
