ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �k�Z �<KlIv���Ճ$Nf�1�@��36?ͯH�n�-��H�%[v��fw�l����H���\� �d�A� s	r���@����!� s�)�`�[�WU�f��,˖��fܪz�ޫW�W?*�|���ltM��S�m�pu%:�j�\L�C�dR��d6�KK�O��'i>�ICy'�g�|�� ��-��HB�8�t�ڧÝ��-GزUCϣ�gc�H����8�<����M��Iձ��K]��[i�ڕ�P���Ұ��Vl�P)
j�c3�EЍ��b<O�w�ӱ�3�Cڪ���j�}[����s���roZ���Ғ��*G|!���p�Ƴ����ŷ�l
����]��s2����?e��@�eZ�;@�����'��?�Me�i>A�6=���R�?�5U=֔�g�%c^��d�������� l��oo�ԋ���gat+��_GfO��ؾfH
�@_8n�T�/�n^7�H�aB4E"��[j�t���g����i9~S��w�d)FO4�D��W�g���q�O�yH	g�	%h��<"�Z�.;�"�#9�Pk�tY�ka���ru]�ۣ����N�c�7oqO9n�_Z��PB��"Onqj="��Ń����a��.A�Cj�厁��@��&N�$�0B���(lLw5�����b�Z*O�����R��AɿY��(Bi�ψ�}A��,�F��zP�c Tf[#�=�q���u{�*a8�/C�lXt���CG���M�p�XZe���
TE�^JΜa�!�_�P C�T�z��)����.i%ΊFe8z]��\ա�����b0��vr)��a�������r&���P�c���M���:���aO��=��	��-�C4�!��i�<�!�.0�T����5M�E��.BMK�w� '(��L4wOv��W�mI�Cǳ��֖)�hN�8+�����?�J$g��2����ozD�r�2��GsyA4ΰ>����q	3�����>av���̖-�tPr�)�I�,C�%9$�+��dI�kY8�~k���F@c����]���K��k�^�x�s/��{�O��n K�\yucY(����]��]ެ>˚�d#�C,M�F�'�n7�zc�Q���;�� �[z���1$��|��?��r�1 ����m�܁%��v�|:Z�s��kƚ�O�	�B���x���I~�u:�c`�x��覍A��։!��O�1����K7~�(�=��p�T ��G���T�K?BF�#�hn|*�yT����t���V}v=q�fՈ'}�L��@� <��{\��fi�j �q#�u�½���)�ߔ�CXUDlC�C��R������L��Tj��/�<��Σ�Ie�!��!!�G�Q�g�
fZ�5�b"�f�J4��$L G|4N��2
<1�2]�� x�MK=�c��VY�U^��)�ְmX��aU������v>���ی�F76���1͎����%$�Nǰ���p0�4U��� f���D4Κ�gX�m�K�C.��!�IՇ5���t��0�b�L4\d Y�*�1�\5]US"�%w�#Ox�x-����(!��T�(S�� ��&��M�+X�U N 	�$��(?�Dj#�c�5�є'�a(�ג�h���B�s�fk�K+������dv��/����ow�z�o�y���������_F����]�ؿlaȹ�0��E�^�����db�/�����.���p��ed��*�,�Od�������ߥ���z��n�V7bMU'��`��2�)�e]t���h!�:��M�Eh�d.�L����W�q���Y������r���3"�U��,��������l�/�����«�3�?�����Od3���R���_��c:j��� lY�u���;ޅ�nW�;ʑ3��[j㛷�Sn�z���%����E���ѹ���6�]���"��o;�ǰX�<��`$�ºԄl��l�4	u��.����Mak��>�-ɲ�`�]��f��uH�-̣H�Aqr������ɓ�sss�Hk�-�9�*nl��˛K����f҇pdd����oI�ݯl�ı~ss���ܜ�Q[7Gop�d-��Z���mi	�	�����lѓ��v��UzlD�\sB�����K��H���t��gwb��r]�,������䟘�b���V�0y���v8goړ��Jb���C�H��L!��9�9��&hpORO��3<\0U�zg���ڨ��o�k�>[��ށ��v�s�R|�I���7|�]��5�M��04���3��� ��̷|�ɠ5�-�X�5��z:"�"����u$]���c�},#�a��(f�M�xi��[B���(�H	���tEd�1��L;��i��R�Ntl�AG�>av�P��X��qq�ͺ��%�T�������ʖ�X]:�D�6c�2�8MWD�&)��	怰iN=J��o�ޝ6�U���M5���#z�-�W�����t |K���p+���?����������)���ͣm�"��|9B�哄y��zO��Mѓ(7�U�=�^�>�$��.�Sx��4LG�(�G,�?��,�������v�"׹i��Q�^�x4�L���?/:����O6 f���(��aH/�1Ͽ���3���O�g�.�@�m�KmwT.T�/ˌ"�I��٨��^(Qn�8��҃���)+��Ֆ
�	��?�D��.�>B���W��V���ӵ$�p�dp6�JԄ%�=�`��C�mb���PT��Lɂ�g��|�S�6&�y����qy#b?�������`۪��9y�����O?ͣO���9{`�jK�z,�͕�&�C<�� �։�۝�2�qp�}�m~l�E�
�Oa"?��&���ʔ��Z_Z<���R�mL_�����u�ѡ��kq�TP	���W~#�QҐJM�Q��=gF���[�v��������3���P�	1S9�S�Th��&���ȵɎaͦ ��(Be�����Z�"��5���S��+.�W�u�>��;���� [P�m�	����)&1�<�	�K8N�'s��f���1�-�ʢ.��>�>�dQ��|�}������K�u���J�8��-�| D�T�pO�"�i`���=:ohރ|�'2�;>2���Lǈ0���s>R���F�!ǵtS���k�΀�ZpO�wdKd�+�jJZ��X+�΍&��8�ߦ������6?6��OV8�R��{�b�'�^\�H�;�E��'<�|�il4��l"U��z�"h�#L�=�2l�mԆդ�VW��?�����;@ f�H�\z�<{��5L�	o�H���ذ2X|M���1l�j�N��������-������#�ͪ�Ύ5TR41br	���Y>��X�%�Ͱ(�q�QOˈA�轏Q��z�˔|G�~/PxըK�<���df��J��qa�ힺI�F���#�'�R��;F��J��֡��	F��0ڂ�Xضq�"��O�-H�~C�b�u�R�pI�����{����3��lP���x(I�Ǿ�c�g��l��A �����Pl�2�
�c9�1Q�>����f�w���u�� Z[]
�Y�{�ܤ���C�ǃԄ&}D�)���!3Y�O�m(��e��m$�
�@�뱥JK�8b,:rq	���-�J!��;,�4���7\8HV#�pǁ�����j #��(�����	�C2�6�6��?ؑ@`���=��;�(,㐄`XSm��5YUp������a�D��َ�Qy+OϺt��M��&�4��F�#�|.�K�<E jS�!��͇��x�4oA�$&��X����6d�Ü���S�o�g��'�@ �]N(���r�Ap���O[�����'���^f�����4�x�Og'���3����]J���]n�{|��k�]��?��Ͽ�Չ��O��d3.�R��bK�e>��Z�VJ^��2�f.�Jd%��q*��5sɔ,�r�\�ofӉ�b:��w����M"	�����a�]�~��eB�\[��.O�Яs���?���J�'WƑ|q���p�{��N���B�r�[!n��wa��`�s7�����2 ��A�:&w�0^������M�<+�`��Og��G���T2>i�����?/�p�k(��u�g������_���7����ί�C��_��?�����o�?�/y��xn�=�z�W�W�����ɱ+�ء*��Ke��IKq)�T��,�S�d*�T�|gҙx|G:%�i�^T�D"ݒs	%	�*B�B߻s��_w���������O���~o��O��3�q������C���~`c:���~��4�ׇ�?��s�������Ve{+����� �/p��MB��^����R���Xo���E�!�Z�R.kŢ��m�W.�r�����,.��v���*N�;�BIX/��O:��[�ZI8(Wjv�+��J��ڊ�[��9 $�;b�PY�%�m���#��6���J�F�
�Ju'��Ňn�~�@zP=h�+�u�Tj��^�NkxeّW��F�z�l�r�`P�_i�%D��(��^�_=���~堖�<��n��j~WY����Z�]�-{A�mTꕞȆV{fi�~�|���]�S����ڶ*��!ծ�k�f�jʉ�Q�~�[�Q�u�_������nj�>�k��{��S��z+m
S��~�`o;=p��'��V׍���xQ�핽�P�K�� r����+�������A��l<��6b��0��O�L{�?v���N��l;���Z�~}��a��//W���'�#�R�� `�#U[��x�DجǷ��j� �ܷW�a�̂��{+\a��!�J=
�`�;=�'bǂI��ZK��v��"9ړ�-�W��6�'ғ.�p-����Q���l�釭��$�+��񊠡�:���vq`Ĵ���'����s�Z�������n��T�V�������.�Wh�N:#���q��(��Lc��Z�e7D�֪,���1���X-�4��iM+Ě��К�B���w��J��20dUC<�j������W��t*���J_<�L-ۍ�a��\Ѻ��t_�/;�Mn�v�M-�prw�F;�K,�W�`4ĕ����>|��4���f"�_-	��4�D���]]��Xz�F��wvv��jv;�f2R>��﯋��_l0ܬ����\M�s)�m.s����( �$�TA��U��]���<-uQ�.0���s�y�U�������5�X)��T�ZS�����x9���O��� ���1x�\u�8�_�ȶH��~�� ��d~��M�`9_���q,�9D�xy�T�����������;A�b�Ȉ���h�|yV[mz�hy]��UJ��R�{to��n�J���GH;ُ+�f��j!CI��/~l$m[�EN;v���s#q#�ӄ�؃��kB�S��g�i^�Yhը���t�����ص�
J�`*Y&l{�q��m�N��Ӥ��V
$�ov]���,i��p�+ҢB���j�mv#`_�M�Bͧ���KsiaKJ���ڄ:m�\��`',����:�5�Y���$��ϣ���S<�i�i���QJ�{Ȥ!�v�a�$��|��5��{(�=z��V�>9�@I�yZ�a����$�H��/?-�@���z�:��!�V���Ǫ���Q@��f��&��2g�26�X�i��X
E�Z6�kē[�Pl���G���:ş�	?to�yE�c	Ćؖ�o��N�r��F�u�B���X�o?U��!�
��K�� }2��|K�K������#�Aɱ�p�*�mĉ^c�$�*�j�Z��S��'����醡����l������_,�w�W�/??���_$��Z��/@n޻_q��v��!�	���B��
��o��vW���Wo����__�_�$���mO��W��.^����v��G.+��wɻ=*��w���5��0��ׯ��Z>�������/ߞ�O��TV��l`��|%b6�f�u�����PϹ��v�c���ș��/`w�����E�b2��G悞���C�<1��|���+�2bɿ��8����o�����m�%�jrM�w�������c]�8"�l�{�T�ה@�EqQwK#b�:am*v��)����b0E꽠2t(N��]'\�q��\�x־3-�~�,��eb���jW,�c�1,��#M��~WJs"W���&��iք�wa �F��ݗ�Ӏ�`?�Z�\�E��ly�<0�v'vK�|hqJw��*�O���9����:�n\��}�9lM�mi��wj�#d6��;�A��Z�6Y �!z(<�g���fV���J���MLx�S���!=��?=�i�D(��B�誰������V%�Z����������[�����@.���I �S}x��йW�DGlJ�&vw�H���x�O�c��1�|,n��ꩻCO���5���^����+���dm��¡�r���� 
�T�6�=�W�XW�k�����t�*\[��Z�־4	�oTݨ7�==����Թ�1��9��.u]��{B��i\|%��+�,hW�:ˈ�X�s�5�j��7���ۍ?��E�.+O�9>����Y�.B�y��Cr���8��ʽ����q�5XH�IoT��=%��˞&���F��a|�I0rY��B9P$���.�$��cA�)�Q���K�ף}Bo&�dwH4}35�N@�5�嫃��k�$���y,sׁd[:��	��!M���z��)�@7:��`b��)�49
(�m��x@1�n��NEXCjb�%�NV&�TbW����r��1��a*>&��jO8���0�GUT�&�ּ=��ɞYo��WIDyj@�N垀B����/��r��mm�����\6���Ŷ����6���w��PxlXL�G}B%��v�������\��n��f
�tѹY<8L>h�6��.����X�md쑞��d����5k�&=ԙκ�ѥ�P��A���K�.|u[��/�κ�ݯ�o$�;_t��}{�En���qXxu:���@�LFs�Y��4�o
_B_$�hΧ� ��y�I�7�_�������������s~}u{�K���������?B��)��=	WsH2�I��J�?����)�a�g7��?4�&�����}����>D;��/0������|t���_�OW�o���@^C�}�2��z�L>�W�gW� >O���ɒ�wy����"��?A����C��޵�w^���������,�{A�gOi�@���7��O��̯�q| n��8����J�����(���>���	N���ϣ��{���)���_�*��6ނ4��	�O��4������O!8��4��_ժ��������?u��@�����?�c��� ���9�c�=���O��c;��l1�D ���9��$����Ǿ�����77'ҟ6����?��]�?	�� H� i m�}�6�����=�?���@��/�����l���'�Y��SAN���y0�r����q
��4 2�A���@Ϻf�\�?���$�i S�MB� [ ����_.���/�?�?����*�ԑ�w������O�����m=��V�=�� ���̐�������g	��_���������`@6ȅ��������0��r����@�e�L���݅�|�������/�����A�ߔ��w(E]����vX��A�c1�p<{���4�A9��g��3$�",r0�E�9|��<�?N]����n��zCil���{��r��%�͂y��dl�0|��O]jo����5�.�*�M��fm�ʢ�G��	��LW7��W�1l�v[E��/[L�|{[#���w����ʛ��YF�/I��x�7�;��r�����J�Ɏq�7~�⦲��s�<�P�3;d��	��������y�P�#;d��W���`��^,�����e����x��0y]j�1��ӕb�:�ʊuߟtk��J���5O��"�ǵ�^k��}g5o ��t�v�S��Ё7��f�3��rM�e܁��5Pm�D�v�<,G�5��X^�pU�}�! ����E�G0��2�����Y}�����X��2���_ ��������0;�B��ԅ�#����������v��j��J�П���d�7i�����G�7oQ�K|OF�1G򽻃m���6Q8^�7,�D�f���zX6��oj�Y�H3<���/��K:D��/��A�ͥδ^A���&�`�ۆ����]�I�2��R�+uv��?i�4��Q˙-骙��K%�p�c�B��y�UN�]�Z�y�D��ѷ��.�$U��5�m���|�A�@�Pn�׃�j���씴��b6YcWCw;��].�n����D� )%fW�x��6ScZ\k}y�����Ȉ]+om����6��P��@���g��`��\#��l��o����\�?y���/� �E^s�������g�W�H��A���!-���_��o: ����_���`��L�?uQ����R�`�����������zQ���O	i�?��%_ȅ��g�?�������������������%� ��e�<�?���!m����������B ��
��/`�����E�J����³������'�h�����M���r�/��O������s� &d�������g������P"k ���9����̐=��̐,����O\��������?H�i�������O� � �@�P�![�O�/��RA��/|������/�O�����'���0��ȅ��'��?�����(&����Q�ּRF\3��L[����i}R���t�ǲ*O�o�ic�LۻS��C9 ��/�f.K�f�"곊�+�"�L�sU�55SS쮎MG}7���h3gPq�����0收e��kK�tF��T���s@�$	�Cr@�$	��F�ō�C�*�␕��*�F�F��+S3,�v���������A�ɐ���Rˑ�$����ȁ�q��}�*��j�q8{1v�����޳���H��?P2K ����_.��������r���8d�ȅ����#�* �A�GP����l�(�%����/��f���␩#���gP���_.r��P迌�����0��\��� ��/[���q���#B �O9��%h��iϣl�f��H�H�O}��<C�%Q�Cl�<�q�4��(���s}�?a��q������tp���J�`���Hݓ��˜/q���n)��~���q,�y��dl�0�&ݣ̀�1�j����P[F�MT��Q�a��^��z�ۍ���%���]q7�`pe���ʖV��/��j�'H�J<\��m��@��L�G�V]���,�V����V5W�]Q���]�T�xΐ���f�l�4���"������?2C����o60���%"��_v���oa�'�pT��e��$�c¶F�>3�jT�1�/�8�����Q��#���[,"Q��g�b�Z�Hh�L�Mv�M��X���~�WWՍjr�!f4ڀ�y��M�I�u�3��]���Q���I��@��߱�8�O��Y �@�Wf �_ ����/0��_��?@f�<�?�ā����?+��p���CgAY�M݃�"2����],������S�=� tJ��P��ڞHT��m�(���zq������;�a�m�:z�O,4�qg�c�hGQfg�N�Zd[ޞ��g��2�����OF?��T�A���m..�:�?ޫR��<o��\��	�2g�J|�	w�B�%����?�*��gQ��2�"��-R����skN���=Ū���bWm@DPD���Ϩ�~k���$��$��`:뙪��!�t��w}�PP��Hd�В��ܿؑ�럢���_�y0�,�)��@z�k�?7�3^�^,�Hb/E�<,���Zk5���zYMV3�Cz�y�g+s����ޱ��h����.��	{$��b��$2� �oL;5�]���������8�(�C�Op�? ����a�W}A��������(��_�����/����g=�����8ey����'�ۑo�^?b�4͢�	��y����$<��!I0�W^������P��"~e�_[c�k�H�6j����e�.�Ɖvv[�U�bE�O�k�o��?l�E-�G���{+ux����������O3ݡɫ������_?��?
��$����)� �.�M� �0�2���PȨ��/�l,d8M�$�e1GSBR\��L���@�)	X�O���������_��Zl��Z�?��i��pL	��x�7��vN�g�,!'��~��˕�V�>R�|�V��Vj���I���D���USP=��������G�A��}�����������=ޟ���GC����ۜ�K���?E������+����@�����}תP�!(����a`�#��$�`���G2����{���_��?����H�Z�o`�~�2������?����:���W�^|E@�A�+��U��u��8����L�A��;��x5��aH��B����,�����nu�ބ��~����ͼRj��̙I�ޕ�|/�R��3�.�k^�[��,��M�w��%���oJ��V�dZ�>�Jp��>3G�,�(�)��/��vDuV�yYD�R�\D��
�����35��0��ԁa?��ׁ��v���$]���j��"1��T�����"͊��6I�c���细~1:gi�t7�f��Sf_���zg��5ѽ�z�[�{���ؾ�5�6����q@l�c�:{����Vf��?�~�o�]�x��R���?�xu��)�ULj�~!>�����R�����{Q�蹝��~��vJ��{����p�ĂSN
�=���8wǫy6Yo�U�-��-Q���v�\x��4���c'�_0�ƴ��F���]���{�e]-b�aã?�����x�X�w�Ϸ��N]�3���߭ ��ߣ������:��i��@5�����_-��a_�?�FB����E��<���i�}����	?������?�����j������7-���~��_~u��ꊣ��/E��寃R#?i-1�_c�
iM���ᅥ6�-ӍKk�����=W'��k������0&E�\�GS�s.�TFfJ�=MQ���d�C�g*� ���{�EI=��I�	u~���9k4��ٳ�	�;nG�Vݹ?����CC4�a2�N��`]�xk��;3�;l@+g5/���J]S�U�]���vo��%�?�xg�h��?\��K{nʆ�K�m8I�l�t祱ܬ��4��^o��m֜�F���`���멩�ES�dݖ�a������4^���U��Z:�V�W���4s=0[,��9)څ��4�0�FCS���,�wL,��ޮ�P�����t�!�{ 	�J ����Z�?� ��?�P3��ω� 2������?�C�����u;�o|?�W�#�piv!X�
��#�ί���J���4�'ӿQ�nE �� {��?\��\�� �i�"v�i<ϴyw �\0�d�>{X��u�I"�������|׋g�ű�����$J�i�:�t��S_g�ҁS.�?�d�.�0cl��u �s!�{� ����,
4b��X�˨G����٥$b.�ْ�؛WӇ��tE�H=;(m�M�%��L��I^�l��~.L����3�uq���ckais2UԞ1��^���qK�f�,��G�]*�K����ʨC��>����������2j��P ��:�8��8���8��W[�D-�?�A�'	�
�����n_lSp������:�?E>���	����F��rl��1�S8��B��t��MR)E0,��xL�x<
����4����wS����?"~��7��nW2�iS��#z���R���h������<|���l����,gmz�K;���eH/�Eш���s�l;̙i/R�j�:�剿����Ȕc����nKs�t�J�0e���V�������Q����C�*����_u�B�a�Ge�A���WX�����������_���1e2�ƾ����Xc�F7Kem�O.�z��6�?���ZY���������`a]�t����DO��C��F��P��qj뛦7>H��Q/��������l�{�n�%N���Y��������z<�)��VD��q�G����u�������/����/������ ��Z�8�0��������4�_��I�bHɾ�eW����y)�/�y���������B��H�J����8{ˌj����7��\ذ�@���KZ�Ɵ��.���q$�n��}#vrc����e/l2jgY�i7g��vznh�L�(�ױ��{�o3��n�|�����T�����Vʕ�t�Ӊ3��~�,�#CQk�y?���PjE<q�o;�tY�:�c֨Gz;�����f�X4[�5�y�eN�$�F5�}6�ClyꞂlp8�;q*��(�����H��b�H�,�6b�aC͛�j�p�?�o�@�� ����+^k�����?�A��H���������H�a�kM���Z�I������]k*���W��"����W��
�_�����?����?X�RS������O�$��Uz��/u���A�?��H�����������'��⥦�����_��u��X�R'�����a�`����/�j���C�G���a�+<��<mAq�?���!!��A�I���?�h���
*�o�?�_� ��P���P�_i�Ǽ:�����@�B�LEN�8��	A�t��B�,K)��,�Ra���A�I&���\J�l��b�Ϣ����
�?��+�?��0��k�/'�Kb�4"�CQ>����X�!}a-�.l&���aഢ�:W����B��b��~�h��Q:�jII��tYnG=�T&vo韇,.z�B
��u��y�����@mw�ée�?��:<��G���(@��OpPOP�����i��(����ă��p��d�m����{���A��A���A�_����*Y��&Bx��Y��x��	q���(��8M�X�x"NY�3*���8�O#<I	�c8������!�C�����Yc4]���b�5�k�l���`O�y�У��]�?����g'm7���%�-�L��Gf�Q)��/�r�}���g�C��2>�s��:��6:��B��.��Q8]ɓusт��[�����Ձ@�o�@�MAq�?��� ���:�?�?��Ӡ�(@��������X�������A��� �j������_����?H����f�� ���\��W��D�I��>=�����a�#`����0��Z��`�#�@B��4����k����}��0�	����A���������H�������?�?����^�X�0�Ŵ�z������W��{_緶�2��gS��������5o�5�qD��h���#/�|�퍳�2m�ŻT�Ճ�P.9�Q�]]��/B�_m4����X�Fk<�+��,S�=�{��>M�|���}'�l�biܭ�L��R/Ŀ�x��ǿ����б��h�SR���A	�{�u�,�J[E�O���J%YMU�U| NŞ{���p��$���a��Kl�KtA>�P�������7j���0�u��~X^���� ����Z�?� ���P3��)Q����4��f��� �?��'�����C�WU���r�ߎ/�����B���WF��_�}�_��Ȩ������������?����#Z��jh5�ISR�ň��|a�t`e|Q��)��~b�áyR.�s7ѹ+ϭI�.�Ww~}�Ԟ���s��^?7�T,^���vq��Iu�����UT�\�C0�L����,"����5�����.^Xj��2ݸ�f:i�:�suҿ�6{z~�gRt�e|4��=�2~He���(K���}�3��,�`7}Q�uQR�q�lB���9,�G�Mǆ?c�lk���ۑ�Uw����e���v��S��.X�-�p��L���Y�Kc�R�i�y�����vo��%�OV�1%1�q&���{��zi�M�ui��'钀m��4���r��z��mq�͚S��htL���c]o�,�h*���2�3l��|���Ë��Bs�
\Kg����ʡp��f���`���9'E�P֡�����hhj���eZ����9"��ߨE�G<�����H�C�7Oϻ}�M�����׎����`�#�$�J��,"�8c�$�Y"ax&�yg!J����c>�)�
Y.&�(Ʃ��J�"<�aG�����?���	�r������i*�f�i�خ����E8���Р��6k��M����6�'�Ցv&�H��L (�w��B^��x���ѩo������i�����:4w۞�7����=���$@���g�apbl�G�����$L��<�=�ߗ�-�F���H�s46rվmkC{X�j���v�=c�ڟ����#�5:7�o��oZ�������x��G�^�>fy
��v��x�I��m��G+OA�����|lj�畧������+?s��6��{�I�յ�~Xvc�ΠP��ίN��b\~�t��v�m����~�+����vJ+���.�ٟ4��ܗ�(6�v5�Z���O_ӝ��k^���w�W3}Z9��z���iaj+��o���I>������6-Oc��m��<��_�I���H���)�m��l㿶�_���m����gk�=����|��$�?��-�����C�u�ߧ/`�s���0�U˔���ӛZ���o>.����������z���Fǎ��5����1 ��= ��r�NW.ˑ�j� �� ��^�|����zu꘹�/���J_}�����T��ʹqzh\v���Q���}5lvޝO>����n��׬��t�Xoo����c�/���il��m�}�~(��y��x�����2=��~���0>c��ZYZ>N�m�<�~W���2_��|ǆ����V�۲�����:߾�U^U����Cc=��j��ATX�4P�g���F��I��r'��=�}�E�����丢i�Ʃ3�ϟ��'�e봬U.�~�u�VoV�ʺ36ώ���g���ÛJ3�z?��9�<(?�D�?���3:����F���lX�gw�����A�3R5'3K�Ҩ��7k�$e]'|f��|�&c�b�H�]��8�f�,�P��h�Y%R�Pe��d�A���+ -޲TfqKÎ����fhhos@̠�A�ԠC��cކ��쟌R �R������v�4阕=R3�T3J$`���?�o��N��g��i��&}��S20-��Fg#0m\���6����96m��đ������\�������}��0s�����9wq�q��{o���~��8#�&6S8�8&a��3�Ӊ�)�"d��M4��Lג��:�Z�����A�N��T5?�ؕ��H����^i$>lQ�Pˢ3�^��1`�a�?�a߶�(AUgjX*tU�۳�#�E�}v5��/Ioĥ��Aa��Ħ 8|�Oz2 �
43�/Z\eP�%�(�̑�f�S����T���.ضڄ�UfHp���k1;Zp)D�;K��פ7���$|�|{��t��;u���5�]��2��fK]	DH���X̞ �]3}��7�h����&<��bR��Ó�Ӣx`(����"��ֆ����~W�>����֚ [�}��R�Z+��?��I���0�̩�Z.J!�A�����Q |U,X�@��.}T�g g<��@rYJtӼ���#q\��K��ViT<U�5�D�c�����l.�������|%$/x����K4�\*5Ce7�E�����0}�wq��WTM��*������ɐ6M�l_7�DIe��1L��]�E��RQt�)]ፃ����$<��m	{��WfC�-F��rNt�+�� �G��
�;�|xy��u�F���9���#b�J$#��t#�Kd�0�nm�ps{8M��PC�����9�s�'K�����J���;�\�jLU�K�2�psO��.LКM����US�bVB~ǖ���g k�����B��l!��l��QpƁ5K�y�y,�, �{�Cy�kic:��&�ҙ:��,���N�S=m�I��"�3�5�4Ш��˕N�zQ-_���)�(�H��/#v�w�~j�D�1�jbZN`�/�w�%�#4�۠�K���B�/�,V�Sb�3��
_��wArW:k�;df�������{�J�L��4ݧ�
�}VL��X��U�\��lV��g�"��e�I�	O�U�'S�P�sj\��;fr%���G��Ҧ��S`�Aˬ�`��J�+_f���װ�l�9��:�z��ެwʧ�����������pu�F�Wo�k�N��=H'������n�{V��j�%�6N#�I�ڹ�xb��_�ɾ���AU˧g�v�v �����ڵFg��D���Դ��p�P5�DR��I�	uF)�RRC�p�>���
�8�Zv�4�z:��{/��G�P����`@�2 +ة^D,��H!�=��<���a{l�9�W[�:2�Q�yt���B���hV[�Ū�z��(\���E�Yk��ށkh7�T*�;��5�R�kHc#i���lׁ�-�u��'r+H
,�Y­֪�@��V�Wm5G�z�}�sr�;�d�"hƆ;��0�y%x*��˽�e�A�}���B�vm��r�.��ʽr�ܭ�᧌j�;�W[���ZE�I~��`s�_�����T)�O2��$�p����<�-[!ƙ���,>����In���\U
3ُk���c�߅���~�Q_���8t�M���`��\���;�#��<v�^�e����B�t2�,D� 2�+#T�rq�9�.ș����8ѼQj�p�v�X?���)߾��S�컚�&���<������L~a��/���R�>k��Eh�!TBj��d�]�ݠX���ã�l����b��Dp��e�mMU2�4 ���I��L\���'�h��N��5�{����L>���*�!0,�>7j�{-��Gj�=�Yw��e��O&���������(�������g{��jP��h)؞�l���??r���1��Pg{��=Թ�����a�Rͩq��&���}���S�.�es�����Aʳ������S{�n��t�4�@�l�0�2��dbi�C��{��N��w.��I�9LA'1e��'�b1����1)1�>�h�;;)�e�w+�&P۴f�ڋ�DQ	�ox���WXώ/���N��g���8y'��J&S>!���P��v�[s�e��
έb�=���:ʈ	ܹ�"��$1@����ؼ�j\C���3�xր�O*�u���|Ȟ�6E?o��kd�E�%AI�;I|~��>�.lOg�{I͆�uJ�Qcs]���ێ9��ǲN�ww����6�׃�Ǘ�Qu�Ü�>����h�q��wM���M�����:�p�*X�*�5�_��Ӌ�?����Ô��G��/��6�?/^���_�22I<�}�oJ|�#��Ĉ�������K�E��]�$@���@#�"�7�����	�up��A%#ᩎ��6���a��3�a��yo� ��S㞤�@5��o ":��`������nj5	BM�ƙ�m,֦��.�����-h;�Y�d�I�&���~�E��Yv2�|�����K���q���h���>��7Yi�o�����^�G���[���L�k�6'�1D��V����:d6U�?	H�p���m[4��G,�`��1����<8 q����|
�i�i��v�����G$��rzQm�(�x�pڸ"���`��񖋗E�q�S1�J�?�/Eo-%�j��D�Ɛ?����.�3��F�d�H��N��H]7��@����I&�� ��N��L�%\y+� 8v�$�3Ʉ&�oґ��W���6ƃ<<� ��1HA���k��;��<'shB�G�f�^�m��_���i�E� �1
f�)�
��L�~��5�Xt^x�}�Ð˲%h"�ĉU��ￓz��Aj��΋��I^ڦ�*�Y/^"q���_��7	g6�z�\�9=m�Lׁ��tZ����6�4�� ������O�x0��ᣬ/������w����%���w"���PM�n��=��]��n�j6��-պ]n�\�mnc�O������w�2��~x��JD��׼�W{NZ{5՗���F��G�9cihc{���u���F�{�w�C��r�ʮ32-���
�W��W�����,O�9\�?>�&J)��K�-�U���ly2��;�,���U�s�p[I� �GPy��d6�u~S�6��s�$�`5�n�H�n�8��ؒ}ߡ��_�Y&����f�B�V�{���`o��|O��gs,��-�4���i�f��t��)R�O����}�T/���7�������o�h�-�Ϊ�;��y�}�;H9�Iʷg����$���5P;�"���f	7���L��k)I���N 	���~	�
>���-"}�����ؙc���+,>,90���J��Ըd��2�c�g��a�q �l��]9�d�܊���z|O� �y�ZI�1C����b���r����e��Rw<����v���6ld@��� �{~���<�Ŗz��u翙���_:�ݞ�<D���_!}M��k��<3	�)���%�=�mYY6�����u�^���l:�.l��!ʦ��]v���/S�f����m���������?p���%ܺ{<q���`�	I�8�)bʖ�i*$�_Sp߷gD3��>����6�¾���$�i�?"�_Ͷ]��+{��;��^�ۘ��ujaO"�b���U�6f�MV��D,��/#��SV��
?Y��֙�n�xx���S6$����xD��	��
���A$C������0}ߺ;���s��&��C���,����ݤ��,k�����r[���)?��I>��|@������Yt(��@� �*�	�)_�'�z�3|:�_W?�Im����`1$e�>BN�������K�w�ط���bnwk�?D�����2�rw�'l�rK�?�����A����Ƅt�~r��"O��i��KK(ӭ��c�$�}��E�2��h�#�ؗ��6�PV ���������q��%q�/?y��K���/���75�d�*�n��m	���*�o�P6�;^h�G���A����U&r^�/E Q��ׯV�`�X�[io��<��}1uW�u��x�<�f�	Ee"d���W�T'M�ו�1�(�|o1�Hi�̹�\ U�}���9�A������F�1�r���W�y(i8�����a�v_$v��4.��+��wO�� ��l�|�nBV �`��5B$��?At��H�ä�%y�c��n��|ȓz_3ݜ�$���(�M(?"�֨����T���s�o�|� ������ID`��<�����$�;>0�D�1vVF�z9��~e�Ҝ����;�� n�۰]Q�	�K�cĳ�Y�މ�'u�y�Ӊ��'R��!���amNw^�PF��w��Y�Uh�m��M�]j<���9$��i�8�d�	߶�����>0���Mͳ��Ԛ��h=��r�e�<��4�����khvㄠ��wFi�K��y0���8�j��j�d�Z#���"�AK�-�J�'`6�L��kZ��,�yf��u?����|E�/�r���Iv�"��� f�g(�����y�2���^�"x�6u3�%�WtpE�/��B�UD�eU��m�C�W��z�V��/}C�t�Y��ҁǈ'?~�em�%��>��p8H�C�j_�Y�c����|}(� 4�Kg�y	���(􆜉����cz���qT v¬����!�r�7���<��:���c���D��/���Zx�eNE���
D]�,��0,u����\��.�g���9��ks��b��e��b���L�lo���=�-إ)�.h23�_�A#����8��J���8�ǹ9q�Ѡ�!��h��yA��7$V�WX`X��x��x�#عU�R]U]�g����Ue�}�������͊�~~������(���%�����G���#.2ѻ/��i����N9��f��cs��7�u��'Ww$�������{�<�'��K�^�����r��_X {���&���v��(�{^>��b��E���ُj�����4����,�{L��L�]�g%�֧���-O�c�%i6V�mx6���aS�h��G^���f�4�˵��G��S'�3f`ˎ���[�s?�`�C����<���ao_�����1��������ɝ�8	���������:�}�?�鏿x�ʙ��[h�\�0��6�H�(�Ykb�(E��b(�j�aFըVW1
�(�FFq��q��o���gw��W��[��x��e�玿��(�:�*�vG���y��?����=���p{ᝌ�7���� ���w�K^���R�unܗz��6��f�v���6i�Z�n��������'�����#�.<�%��X>��	4��� �ߏ�>%~�g��ƿ���ÿ&���[?����?��|�[_}�����1��������>�rŏ\�u]��0o}��h�����E$AjG0�ֈ �F�\s����kx���(�T�ڈ���TCo���?��������?��O�N������.�C�C��:xqk`��סo�~^���5������w^;��{�R>��=��{�?�_Z�@{QC�2�r�ei��.�-s�Z��B����>j�����Z�v&+��f�^�hp����e��V���ԗ�$��z�5��KLo][Z����ߐ����4*�+S�-�R����f�e�f��Ҕ�Ӊeq�B�EE�I��4�w�\�4�W�Ԭ�5[R���b]�wŽL�Y�V������D�u�Y4H�Sƽ��4�-b���b�q�l)�81}ц�4ݮ���
�w*�Ur��7��9Z�s�N�#�Qa�h�3
��db�t�A+�
��*n;ʠ�%���n��o�Lͦ�LB.��N�悐�䑁3�b��6�[j�)	�9�c]����c�]�F����Y4V����LxN�%�e�uY���9 G�Gm~��u���z1��ro��X�f�?��_�r�.s����a;l�6SQy]������<d�
�0��1vԨs�y25�Y1V6��P'�|���1+JO�5B�L��0)�5�rS�G��%�O�����zS�=-*�g�b:4k��جW&��1坢���/E�9Z]���tܤ���ܤ��G��Sr_Y[-�������K����䔑�Xg�W�b/5!�e��,�q��Z��SL�JuJE���5I'��7\"�d��p�t�GR#�#�?��N��(LJ���z����=۸�]�F<�V�1Ɉ��T�Iv�n^��j&3�Y��4��1U�z�i�/���b��L ��5��aQuN�%*ܲ�!�q-o�
N�����.�y<I���Ĭ�z|_�EG��q��R<��ƌ�(r�Hr�E�ޙ���8�B���q"�v�<癝���𓲂�(�=G�t�
�9֚���s�N�R#6������ o��\�� ��\��D��{ ��~Z�k����?�Vs�%�����qdʠ�PIGl����B�=3'�أJq�Ө5�*��1 �Q	L(�X5�*["h����&.����?Ob~�j�n�X��`P>=��3�����n��N6D���X���� `��!]�q'3b
�#X��N3<b'��aE��"�	g��T�c�d� 
�BfXς���f��d��(��/�e�-�q������A�ݟ���;~���V�o�|��]}���x�-6���D��Lk�o��\v�2���[������]xI����'���n:r����N߾d3����v���п�
���C?y��OV�����߃~��f����/���ܥ��zj�E;:�(#��2�Y�'se�Ѭ��|Uy�6_�������~_w�%�p��{]~�\�:�Yr�皹�uT�6s�%u����˱�2pYb
k�x仭P�'QJ
�0z}e,D��pH�Y��#�������`�D��g5�-��b�I�Au�t���J<dt�l�H���vkZ}ԏ9���ѣh�4/w��n��D��DPV�̒e��0�je�H��8F����4Gg�� ������x�.˨5~�5:�t���I�j�7ph:�*B��*�b�3���C���4��Aem�ɖc5Di��"+Z��:匫 t���Q�Sp��!�T˘}x$sM$�b,���Z�:�R%����uQ2���L$[�����o^�iXO(�6BY�$¢X���8�⣩�H�r������ 1�����
daN���[k�6���ʜ�G$�2K��Y����f�]&.�q�eN�ͧ��\����;Xh�6]Y�����N�d����L8�v!�ȼݰGFI��]5��,Z���q�X�d��k�T8�)r����B�� �Kiv��u��:WY��V�`۝p5M�� ����9&\�%�Y
e~)�Y���䲳�Vv����S	��ru!>��fs"K�A��餺P�0�:KH;�:��0'�-ZR��z9��bբ���:J���yr� L�):]uP���4�S��s
��c�7D���uk��|�j!������x/����?�&��K�DZ���ԐH�IW�[e�KŤ-5"�����א���2$Sa�Mp�!)�,�	���ژ�S|�1Q]wlmLr��_���^nP�	+"��$��3��AO��.O�����n���*�E��!���&M�+�0��)$M��B�؊E�yt<1@t�z��-�9�,�*� b�5wTɍ,G��p\�Cm�ֹ!記W�0�Ơ0h+e��c	\�M��(��B���4KO� 3Q\Cz���a2F!�2N~Z��j��H1��9\��fΔj�^�����u��.����_���j��-]�2�Ҷt�l�nt�շ��J�+o����hN�Cc0AG�ǿ�x���5��	4�]�6x��D�ir���r��x�>|�y�����6_/m�y�^�^ �����[��E��j�e�&Q�+F�.�Jm��7�ݸ:j�N��������=XQ��:�_Y\���j��=/���n����xe�\wWg3	¡c���!=�������O�j�ѓ}���E���������a�*Ǹd����1����>��*?��扞��N�x���d�3��^��O�f�0�Ur�w�f��Mo�l^s���ғ�><��Թi�͘=s��4˞{c�����;���x`�4���~��Q��M�P��ơX7D�w�(�*n�z`�4���i0�u�h��p�����䣏>z7�n��T��S�u�,��c�����O!�G� � �!x�~�3:�G���a�wa1�����������N\���<�����_�8S�'� �}`K'eLJd�'��b�p�iU*�y�+�����%}!ZB��n��e�� ux�>�U�㢐�Z��+��d2ՙۖݵ謃�F�3��x��Q�h���t휙�w�����ؗ���`;��p���� ��L���}�s���������������0���9������e�mP��]�A_$A�쨞8�e�E'�b�=#L�qT3t�#e-+���8�>�%e�\-��tn8aGr!��K��\PY24/b]��j�~`�Na&��.�^(�ј����U���J�P�N���x���
�u5Fj�$v�}ܹ0������;�Е����_wW��=�����T^g����?�4x���g����y�x��A������ad��	�u�_�L��*<�x�O���!����$���h����~�Y2�.�?�����?~�/��ʩ�}�����G�s�����7y0����;�G���'������v��w�����I��9Ǿ��������A�� H�����=I�>�{���A�?��������^J�`�_��������s��{�a����``O8�Fv�?�����A�g:���g��C��'�@��~�?�S |F��?��� �Cw�$��}�@��k0`�8��<'���{APm)��T[�N�%�{���A����~�?�[���"���m�w�����@�?� ������!���� ���� �L��'���:�ld��Z���������!�ٙ���A���� ��N����(��U�|I4jM
հzSm4#Q\�Ȩ��1��l�(�]�cL�d��	�[��������?B���������_���A̻1�#0W�)l�4��~%)�C&�/���H���"Y�LEg�J!���A!:
Wuu���b�Y����I�ȩ	&o�5�$gu��	�bbU+R���>�G��LLf�s�����/Ϻ�w�`������/�o�A��p�?����!����?�����뺁~߅g���������Ǩ����B.���e�9T]������K�m�=�+����䋝L#�Q:�Z}�����E�JG�c�Ǩ81#Qa2��x�$��FBe�=�c�Ơ�(Yj�Ćz8Ŏ�y(���Uq�?���?�]}�>�<�ԟ!�����/�|�|�|�|����ϧ�@����8���p$�������/s��2i�
���Ss�Pш�L��?w�O�<u�wz�#0�үu��g�ںU��y�W�w��r�<�@DTPT���Q �]���������)�;k>%�\3kΪ��z�����6��n�J[�fo:W�i��g������ߟ����$�{��Q>(m���&Թ�I��$��U�A����h�p�E���6���`4�~E��*Sg����VV�ME�<i��g�nS��b���A�L!i��ծ���>i�ޭ���/�oGݾ�6�u���{-��W�Ϻh��:3TF=���v�f���!RX$���4<�V���7���8�3C���|*�i�S/�Krg][��r�����(�y+0iԪ��q�x�����ל���9	�����?��p��C�Gr��_4�����GA���q '�C�G��?6����������a�#�,���w�a�&�X�a�� ����	��2w�!��	���<"��]���������B���������@.��m�G���/���<"����N��x �`���� A�1��*
���??�?��q�?��/����D��`���� �?���ք���_4����_�
����`������p����P8�CeH� ��/���������b��B
.��X���	!�����?@���P������
��,�ڐ� ��k�?"�_����@�?xl|6���w��GX��8���T����Է�M�6���lm������G��j������K{
��:�`�?����S��ɷ��n������b�٪��,J�z}�IZ]�B#�]�}��i����Ff*'�v�6ן�٠z�qb����`�Xt�/���Z�oj@�k�?Հtr5�\���,M#Q]�R�l>�����S���O�Ҵ�*��s���-MH��cv�z-����՞�i���/�%?2����������y0��?��p��!����������O�aI��!���`�;���#�������?�B�4�,�����#�������C��������������p0�� ���)�6��! ����	��1�?r��8@��
/���HDRdN8�g#��E�g6bYZVB�	"It	A�Kb��;��O?���'����{���x����;V�b���a�^��YScC�5��N[�k���sSן?΍�f�9���nܓ�RwƯe�9'ҙ����8���;�t8��Ѣ�2�4�����ީt��r���d��];ɹ��ǋ�2��O��C�9&u�,��������h�ɠV�C#�v����Omz�fÿ��݋*�����Y
]��%���Ł�����p���ֿ.6��K�%A���+���%��r0�W��Y�����<�5g�u�Y�a�Q9��Y�n_����O���m�$I*|��_�˲�3��@����5����_c{���Y��\s��ìe����N��ܤ�i�/�hx\�,����]�A�a�ǁ��� ����+�{��������/����/���W��h�b@���_AxO���/����i�������=dޖ^�ź{����W꿟�H���(-�t����mrK�LJJ�(O��i�G~��Vþ�0��P�2�ǲ��D�;���+�U/)^tP�$iݯ1��l[�r�k���2���<�y�}�y��k��H�\����=��T]�����_ ��h dt����c��Ȳ��<�.�t+�pY:TE��W4:��o�h���X�˛f1֗�L�^H��ڷ���֋ԛ��d�o,ЦS��Nb��7���z.�YO=-��ɉz�&��֡٤x]z�4P��T<0������ߨ�cw��Í������*����9���H���tW�!Ұ��������q�������ŉ���������_0��A�����H� e���Hf��o ^>�0�|_@��L_�\t�Df��py��
�>8��{��>�wyD���2�W����dB�*�ڱݣ��1
��ґ�;���Cu���f����.[����Y���	�?�h���/,�l���E^������?Os4��� 	��
w��"��� ���k�C���"%�]��@�h��Y1���q�/B@�� ��	X��	�������,����"ƑZg{�=�>M��n���[4߇��/�+��ӱ>������2�3q�kZ�ߏ����f��� �Y�a��������a������/�����_�����-�?����Y���?������~��s�u������w��?1���������:��������?���,M���A�,�����~�!�P ����w�_`�&���	0E_�/�������?@���E_�/	�����_�������?@��:��>����?2o�?^�������r纮�����[����,{�lYWj��ν\��I�̵���9���R�������ٗ_t�8��p�j��C��Q�ؚ{ˊm�c�{����@���3����ւ�7Om���k�+�Q��y	Q��*��<F�5�[3��ɁQ����r`���?������ǻ��zER��)����o�E>�I-\�GZE^,Ғun�O�j��N��rj��,�mGI�`Ι3��J�L�a�V[uwЩ�>5=W�Ρ�l�Chv<��Da��Ȯ�y%~�~���.M���̕��O������Ȥ����%(ֻ=���k�ȳ��Be�a�nl�l��R#�����[�]Q㺐O7�xp������4��oS����GvT+�O�yy��3m���Ψ�"/�si���])Nx=��ѹ��Ǻe��'��0�zYG5ײzH|��:f�]�JA��-��n�O�������?, @���x; ����D�����=�C�, ��?	6>$�����a�{�߼�����g�Z���iR���f(�6�b����_]�e���K��a*����F�>Kkݞc�֙R���'�i�ؽ w�k�,�ճ������c��c�`��׽���ʠ^�2^meD�F߶)�|p1���
mL�S��J[�f���Qssq�����y���l�̅L�L�A�W�j��bЗ�/��ڨ�Iw6li,���";]�J�I�#�y�d�yc��iM[�M�\�6��zokqE�_�xU�j_�?\�g�������vc��4KS�]����m�ꆁ�Z��WE{�օ���V7�^�SQ���閫�i�)݈�~o�2:+�@)O��T����xy_9�rl�]�!nVN�4�T7F�+�iߥ�}��F���t�8^G��k�~D�?�A�7��b��9 l ��_[����_���d���Ol �	�_`��C�7,x��w+���ҷ��0�1E���q�����O���l!���=�6Q��!�������F?��������4p��������p�z	�ѹ-��tǔ�{�Ҙq�l&�=/������Q5v1�'l��ú:�R�l`�|�C���/'J{�c�M�oP$���9 �%��4ިQIW�F����<l�钯��:?�L M,1�����з@S�x��P{���!��X�[��U��z4���I಺��R�MI=T�Nm����j�g�7�Z��MM訂�E髃,��?e����0����K��������������,��  n������8��?�����om����̃�'����f�]� ��������޼��������a.bЧCI�#:�d��#Y	����@�Y.�A�'�8�#KH�	!� ������4��?���o4m�ͦ�����l�Ը���.3s�\��J�;w���uv=u=�����\E�T:����ܔ�0����;��$T����k�9���`�m6�^�Y�劷?5+��B͞nl��(HX���gq(x�ϖp�[(HX���"�����{�����/�	���8�J��8[8��V/��֍��J�(�k����1/�Ye���&�=��^�Ⱥ���9��V���vSk2[�+n4�Ҕ�O��G�X��eo���]�<OG��T���]i�86)�9�5�}e���������Q������[X��W����� �_P�U��꿠��`��_��?�� �����h�����=��z��o~�Z}����ݡ�����?\�U�_��n��*�*�X�L�/�@�Gz�sI��-�^P.Ue+���(�c���Ԥ�o3��N�N�q`�f<�N�A'n�Źz>g�6�R�9͚���g���!'��MN�k�A�|��=��n�~���^U�m��^�i�Q�.�:Wm��b���Z9�ۡc�Zŗ�s����y[�L9��m��5��b�@�W�j����JŞ�X�}n&O��}jul�Qw�WJfs1n�3��'�V�hc1�x��JEe7qR
�p���h�����?�V��������3|��#^I������ ��C�����������J*�������� �]��?4w%�����_y���0����W��Z����p��	x��x!�����#��Y���A���0�(����y��c��!��������y�F��
��_[�������v��/D���h��� ������[[���?���A������O.p�����������������_,���p�O,p��G��� ����C��P�'ܝ���WL������|ߧy��&h°!�HA�"��-�r�!B���8���J�K!�D�`�O	������$���r�ø��g+��j:0��~_Տ'���޵w��$���)z��$B���ٕ� ���f��-!���f?�vK��Nn�Du�uP�U���uU��5i���\�A[�,����떤�Ʒ׽�==mX�P��]��<���9ϰ��>���I�Nk>Zs$3�v̫��WmT�>��"=.�������?��Na�O���x�?�?�>�%��C��������C���Tz�����߃С�?��w�t(�����&��������x��q���s�?��B����R��B�@����F�A�IER3Y*�\��2�Ȃ��3�|F��(�
LӔ(�K �C�������?C�2���׺��eR^��8�ջT�1vӂ��Z���۫��|��˩F�.�vyə�U�z�̚���1&��u�6*�i�F�i7#�߬�W�{W7S[v�Q���עnr�E�(�����)��q��x��������O�1�?���q��t
�O�{����A����|����cS��1�������������!�L1���t�O�Y���?�����G��c�?:�g��b�?�������?z�C&���������������9�1���A��?G��oC�b�����N�C������ǃ�I���Lq����}��б�z��}��K��?�+���o\F�Q�Z��۹������ί���}�ѶN<����=��nW��9#Q+A2�H�rFC����]w.�J̖}����	�Eџ�k�>]XA���}�T0画�J�nX[Z�r�bvs�f�w�����!�`�����oBp��k�k?e��/X̎Ol�����=İ�&L�֩�=E�2�B9���(�,h�Lf����63l3U�
�ct��_er��.�h�Јq���\����En=��ac8o�t.��?`:	�/�n�����N����8��{��������������o��ǃ�i�|Jԡ���}�?e���?��?��?��?��?��l�����8��{��������������?��3���������x��x���?~�_�6��iz-s�<_+)������ό�S̗��:�`f�O?ip�ac��3�Љ��ܬ9�*�y�8�W�)3�������
!��ȿ5�o�ª�g��V����{�_O&�5�{٩D��j��<�>O5'D}�7�_���F_��S�j����N�i�&�MY	�2~6�Alb[���0��:��+����(;&�w�"C
[�
��IWf�^�1���|�Z����Y7W��n������h�7��F�1����t=�ȏ��_*4{y�i(�nnL���צ�>[o0t��>|)\��c[�JL#pջ�Q<3e�����wf�����^��"aw�3�6�[�{P�V�&�r��SW�*-�^������cH�i�N�p�S��������}1;*�&��<_��g����䔔&h�l-g͛Wk�*[�B��Q�{=�zب�ER_st1�T��.��c:	�/����������fp���c�������w
��y"��_��:%�WT)���lZ��\Z��]Ȓ�bQ�$������,#�P��e*#�dF���L1#������t
�������?��������6]��N�S��XNai�W�9S<�,��ܸ�Ӥ
���)��������O�av\�k�5���ܢB�L�c{v�jw��iM�f��;_���K�A�M���R�EJ�j�3�+AT����o�S����?�GG��]#^�=*����ǣ��������	�Xn����ߐN�c��x�+�?����^�?_�#-��o�Us̢���6/���x*g{б�����3�?�vJϋ͵��*.�W1s�����e�[�ir��]��4�Vi0읯����y�7��9ߑۣϐ5:՗����{+���O���#�	������ž�g�Sx�+��u<�������_���8��Ǎ��6�1�$�|���Ggb�����7�G���{|����n�cD�ͯ��U)����������(���3������udmM�� "H�{ �m{v� d�ʕ�!O���*�7����,U��jL��Z�ڽeR3r6�U�}^N��+_���i�W�V�{�:ך�a=_�fx�<�m^�R��V~q����=-6]s>�ƲOh���n�EM�������Π���6��e�3}Æ�%2Ք��a���%���w�+���	M(�׭L��4�A�ipZxa�3i��\�d����j�#��0��2��;��kd���TA��e���Veu�F-	u��r��ݐ^8�V���),�`�j��\&���jT�{�|m�6ө�zֿ�ݩ�i4���?��ƫe����<M��?�����A g-ֶ�M\ �te/��1��i��@.�$�� z��u����t`BP�����,DyT�D�P�į#���e+�L�$@	���c�X*��0MQ�M%� �R�󋫴U��_��
x�	���b� J�\���e�鿺l�񬷀r0�=A;4  A��j� C�]а����jT�"��;�j9�tN$;�^�7�}�c�]DxS���_-�����ܧn�{������s����p��kh��Q2Dz�0tYw��l��ɯt�-ώ���gr���� a�|��/�,��u��¯�6�">A���hѶ�5.'�z��ěGs�c����J(��[ M��ۇ'��.��t*_@h?���|��7_	=�ŇC}f��l|n�!_���	*|̍����-d�غ1�<0�%�,�D�c׸�E�p�����2������$7���-��BI����L����ؒ\����v)j�j[�2����h)/pB*����Y`A[Bc�|7��Bۧ��ZJ���kp�R���ζ��=�(/�ǹ�۹Q���:E%$�ABUH�\ J(��*I��B�����F�_�ig�N0��� i�sˆ��u��m�j��.���'�:b�����ZbX���g����ߕ��)gy��Ho������~�K\KӛKhD5fB�9x����&6�]<U�W�s_��E�|P}�>*C�k{��Ǫ�y3�_�;*ش�f?`#֨qǘ����A�"���aŦAC Y�$�A�p¥��W���.�e���X!DGL�"�C������˖a�f�N����8�HG�H�q�_��C£� tkۨV߾���o�P�HL�O�x�{?]����#�xn�,�{�E���(���b���y��}2@�8�?��O,ߵ$O7���z[����������ec�� �s4h�?�1%���erO��@��e��̰]���ʕ�6ӯ^~l�JD��]av��m�:�W�Hr"���AF!HX���\ְ�H>�WB�'%|����h��ذ�����m�r��$l~%���?w�a�Wа����?��柾�Cei2���A�8��.�'�A`�e�!{b�}.jhR���6��!��DF/>2]���92I����m���c�e�m���/SЕS{�E2�����]��� {*K|��S8_�o(|����t�/����X9"E)����$J�l�HA1�����˩�մ�WӢHI��R$UR�9��P�r�3#��8��:˓Y��	"f@�p&����	�j<�I�� z�܊�������LE)�%I"��WD%MAZ&Ţ(��]�y��+��()�La1�z�P�t�ŜQǀ���/��$�OAo,-Ûí�J��J�,�.�ښhL��C�6���I1�#�k����d|Ec�'ަ��n��"���M���o�J���KJ��r6���L���{�K2��bn�oO�5�~�U���Z��굱^�,^n����P��,t�j��}^|�E���w�ķ��Uoݾ )k�4k!���c�)9u�����UZk+z�Dё��X��}���s1�t�N�]��<��`[��Nj��x^��B��Qh���������&�\��c!�Md��|�����*#4�V�1g�%�Tv��|��n	���g꫋T*��,��h�lόl���-�����[$��i�nލ��ЛH:���Vjq5�h���s�fY��6���խ5P�.7jt������:Zz[o3�Ԑ{�6<�\�ey�TA���L����>�2=�����~'?�p��)��t��W��l�@�R}X�y�GqJ"�=�r��*|A�ӻ��.28%�R?�ŮL�y��g�</��8�d��:�~X	n������"+��;_�)�H$0m�c�l��>�lX<E�'#���Q��Q��t��EݙBs�h��J�!?��Z���V�υ��X�Yn&�������t:���?*�������ӇKI���Dg�_��WxI��n;.��m�_���M���A7'I൓\�gJЅ2^%�':��ِ��~�/�L'����+�(�nٳm��� ��u�������@V ��	�<�����m�5�r�����v�����,|��l{�B��.裦>�s8k�E���>(�T췳�0�t��`7�*x� 3�G�ySf\E\_έe���0�\H|��W����Rɇ�i�������6ѰHA#��m���5N�[��������!z���k{����wn���/�э�ٛ.�4��@6�h��!�jz+�;���������,���w��I1��N �3K���=G�� �D����	ϲ�	��8'�o���+���`�C������������l���*��qz]�#U��
����*�;H���:r��V����?���ë�O�]~���Ѽ/���'��<��,T���Q�z�
^Jï��h��mI&�4��u���PK!=I��a<T�ϚHl�/�H����������_p\����N��_���@z��!�V�O=˶�_��^�`
��uQl�F���iU�nV6I~�삒C7s~x(f��i-HC�����ۻ�ަ� |��-��֮��Aq�$�.��f�	�yXNR	E����;�݄G��|�$��x�5���$y��H�l�#P�:��6�曼�U��.�	�I�ё2uF�a���'J}3'h�ݐ��W{���%\]���p���ā��9���ϼ�*���)c�ĉ���M���<��7��]���&��(KUeN�VS����$�v�H���ݜŜl��	����e",ee`]�32��Z,?}x+���VTѷ��[*��(��0{`nt�����7]�o^�},�z<����m<3�s��CGe��}���J����AI��u��}'��������^t�0��&�0��X��A,eOF�ELGmt�x/Z/ƣ��%�����k��tfP��f���9Ժ9m���%ђm�f�t���
��V�K�$�b277��4Y�ZV.����p�;�������)�Ң�xj�\��m��͎�H ^oÂE�JIo#	��l=s��Ѣ�ᑁ���r��9����������r�׽�w���:{R[|7�������=���}$#H-��>��G����%3� �Si��
�+�"� �2/͛�iOo�U�a�����5�2�6fdJ>HzT�FT�����M���R	�T�Ǔ�Q��gNˠ\��� ��oI;r����`0��`0��`0����n�7 0 