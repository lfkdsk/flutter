import os
from shutil import copyfile
import argparse
import sys


def auto_add_sign(pro_path, development_team, specifier):
    if not os.path.exists(pro_path):
        print("pro_path: %s not exist !" % s)
        return

    pro_file = open(pro_path, 'r+')
    lines = pro_file.readlines()
    pro_file.close()
    pro_file = open(pro_path, 'w')
    line_length = len(lines)
    for line_num in range(0, line_length):
        line = lines[line_num]
        if line.__contains__('CODE_SIGN_STYLE') or line.__contains__('DEVELOPMENT_TEAM') or line.__contains__('PROVISIONING_PROFILE_SPECIFIER') or line.__contains__('DevelopmentTeam') or line.__contains__('ProvisioningStyle'):
            continue
        pro_file.write(line)
        if line.__contains__('ASSETCATALOG_COMPILER_APPICON_NAME'):
            pro_file.write('CODE_SIGN_STYLE = Manual;\n')
            pro_file.write('DEVELOPMENT_TEAM = %s;\n' % development_team)
        elif line.__contains__('PRODUCT_NAME'):
            pro_file.write('PROVISIONING_PROFILE_SPECIFIER = %s;\n' % specifier)
        elif line.__contains__('CreatedOnToolsVersion'):
            pro_file.write('DevelopmentTeam = %s;\n' % development_team)
            pro_file.write('ProvisioningStyle = Manual;\n')
    pro_file.close()


def search_project_pbxproj_and_auto_sign(path, development_team, specifier, need_open_xcode):
    if not os.path.exists(path):
        print("path: %s not exist !" % s)
        return

    for root, dirs, files in os.walk(path):
        for name in files:
            if name == 'project.pbxproj':
                pro_path = os.path.join(root, name)
                print(pro_path)
                auto_add_sign(pro_path, development_team, specifier)
        if need_open_xcode:
            for dir_name in dirs:
                if dir_name == 'Runner.xcodeproj' or dir_name == 'Runner.xcworkspace':
                    os.system('open -a /Applications/Xcode.app %s' %(os.path.join(root, dir_name)))


def parse_args(args):
    args = args[1:]
    parser = argparse.ArgumentParser(description='A script auto env.')
    parser.add_argument('--hash', default='7SSCMQ9R9M')
    parser.add_argument('--team', default='Yiming_Zhang_Wildcard_8AYKKJ0UR9')
    return parser.parse_args(args)

if __name__ == '__main__':
    args = parse_args(sys.argv)
    search_project_pbxproj_and_auto_sign(
        os.path.split(os.path.realpath(__file__))[0] + "/../../../", args.hash, args.team, True)
