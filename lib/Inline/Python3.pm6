unit module Python3;

use Inline::Python3::ConverterService;
use Inline::Python3::CallbackService;

use Inline::Python3::ConverterServiceImpl;
use Inline::Python3::CallbackServiceImpl;

use Inline::Python3::ObjectConverter;
use Inline::Python3::NoneConverter;
use Inline::Python3::IntegerConverter;
use Inline::Python3::FloatConverter;
use Inline::Python3::SequenceConverter;
use Inline::Python3::MapConverter;
use Inline::Python3::BytesConverter;
use Inline::Python3::UnicodeConverter;
use Inline::Python3::TupleConverter;
use Inline::Python3::InstanceConverter;
use Inline::Python3::ModuleConverter;
use Inline::Python3::CallableConverter;
use Inline::Python3::TypeConverter;
use Inline::Python3::Perl6Converter;
use Inline::Python3::ProxyConverter;
use Inline::Python3::ListConverter;

use Inline::Python3::Config;

sub py_init_python is capi { ... }

sub start-python is export {
    py_init_python;

    $converter-serv = ConverterServiceImpl.new;    
    $callback-serv = CallbackServiceImpl.new;

    for (
	ObjectConverter,
	NoneConverter,
	IntegerConverter,
	FloatConverter,
	SequenceConverter,
	MapConverter,
	BytesConverter,
	UnicodeConverter,
	TupleConverter,
	InstanceConverter,
	ModuleConverter,
	CallableConverter,
	TypeConverter,
	Perl6Converter,
	ProxyConverter,
	ListConverter
    ) -> $type { $type.init }
}

