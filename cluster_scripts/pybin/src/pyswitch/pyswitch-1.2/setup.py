from distutils.core import setup

setup(name='pyswitch',
      version='1.2',
      description="A simple yet powerful 'switch'-like dispatcher system for Python",
      long_description=open('README.txt').read(),
      author='Michael Kent',
      author_email='mrmakent@gmail.com',
      license='MIT',
      py_modules=['pyswitch', 'test_pyswitch'],
      classifiers=[
        "Programming Language :: Python",
        "Operating System :: OS Independent",
        "Topic :: Software Development :: Libraries :: Python Modules",
        ],
      keywords='pyswitch switch dispatch',

)