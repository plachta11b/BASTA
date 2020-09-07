FROM perl:5.20

MAINTAINER "plachta11b <janholcak@gmail.com>"

WORKDIR /

RUN git clone --branch cvs/release-0_7 https://github.com/biomart/biomart-perl

ENV PERL5LIB=${PERL5LIB}:/biomart-perl/lib

WORKDIR /tmp/
RUN cpan install XML::Simple
RUN cpan install Bundle::DBI
RUN cpan install Log::Log4perl
RUN cpan install Exception::Class
RUN cpan install XML::DOM
RUN rm -fr root/.cpanm;

ARG source_url=biomart.org

RUN sed -i "s/biomart.org/$source_url/" /biomart-perl/scripts/webExample.pl
RUN chmod 774 /biomart-perl/scripts/webExample.pl

WORKDIR /biomart-perl/scripts/

ENTRYPOINT [ "perl", "/biomart-perl/scripts/webExample.pl" ]

