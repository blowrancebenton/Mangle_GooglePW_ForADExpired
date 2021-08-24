# Mangle_GooglePW_ForADExpired

    License: http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.

**Purpose:**
Restricts Staff/Student access to Google accounts when AD account is expired by randomizing the account password in Google using GAM.

**Requirements:**
1. You must be using Google Password Sync ( https://support.google.com/a/answer/2611859?hl=en )
2. GAM ( https://github.com/jay0lee/GAM ) must be installed and working
3. The user account executing the script must have access to read the AD attributes: Enabled, Mail, PasswordNeverExpires, PasswordExpired, ExtensionAttribute2
4. The user account executing the script must have access to write the AD attribute: ExtensionAttribute2
5. The user account executing the script must be able to read/write to the log file mentioned in the instructions below

**Basic instructions:**
1. Install GAM and ensure that it is working ("gam info domain" should give basic information regarding your domain).
2. Download Mangle_GooglePW_ForADExpired.ps1
3. Edit the configuration section of Mangle_GooglePW_ForADExpired.ps1
4. Execute on your desired schedule
