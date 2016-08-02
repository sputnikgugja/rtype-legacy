package rtype.legacy;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

public class RtypeLegacyJavaService implements BasicLibraryService {
	@Override
	public boolean basicLoad(Ruby ruby) throws IOException {
		RtypeLegacy.init(ruby);
		return true;
	}
}
