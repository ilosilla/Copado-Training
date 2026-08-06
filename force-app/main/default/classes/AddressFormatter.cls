/**
* @author 		Ramón Prades
* @date 		October 2023
* @description 	Formats an address (country-specific)
*/
public class AddressFormatter {
    
    AddressDTO address;
    Boolean includeCountry = true;
    
    public AddressFormatter(AddressDTO address) {
        this.address = address;
    }

    public AddressFormatter excludeCountryName() {
        this.includeCountry = false;
        return this;
    }

    public String formatAsString() {
        String[] lines = this.format();
        return convertToString(lines, '\n');
    }

    public String formatAsHTML() {
        String[] lines = this.format();
        return convertToString(lines, '<br/>');
    }

    public String[] format() {
        switch on this.address.countryCode {
            when 'US' {
                return this.formatUS();
            }
            when 'GB' {
                return this.formatGB();            }
            when else {
                return this.formatES();
            }
        }
    }

    private String[] formatUS() {
        String[] lines = new List<String>();
        if (this.address.street != null) {
            lines = this.address.street.split('\n');
        }
        String sep = '';
        String cityLine = '';
        if (String.isNotBlank(this.address.city)) {
            cityLine = this.address.city;
            sep = ', ';
        }
        if (String.IsNotBlank(this.address.stateCode) || String.IsNotBlank(this.address.postCode)) {
            cityLine += sep + this.address.stateCode + ' ' + this.address.postCode;
        }
        cityLine = cityLine.replaceAll('\\s+', ' ');
        lines.add(cityLine);
        if (this.includeCountry) {
            lines.add(this.address.country);
        }   
        return this.compress(lines);
    }

    private String[] formatGB() {
        String[] lines = new List<String>();
        if (this.address.street != null) {
            lines = this.address.street.split('\n');
        }
        lines.add(this.address.city);
        lines.add(this.address.postCode);
        if (this.includeCountry) {
            lines.add(this.address.country);
        }
        return this.compress(lines);
    }    

    private String[] formatES() {
        String[] lines = new List<String>();
        if (this.address.street != null) {
            lines = this.address.street.split('\n');
        }
        String sep = '';
        String cityLine = '';
        if (String.isNotBlank(this.address.postCode)) {
            cityLine = this.address.postCode;
            sep = ' ';
        }
        cityLine += sep + this.address.city;
        lines.add(cityLine);
        if (this.includeCountry) {
            lines.add(this.address.country);
        }
        return this.compress(lines);
    }

    private String convertToString(String[] lines, String sep) {
        String result = '';
        String auxSep = '';
        for (String line : lines) {
            if (String.IsNotBlank(line)) {
                result += auxSep + line;
                auxSep = sep;
            }
        }
        return result;
    }

    private String[] compress(String[] lines) {
        String[] result = new List<String>();
        for (String line : lines) {
            if (String.isNotBlank(line)) {
                result.add(line);
            }
        }
        return result;
    }

}