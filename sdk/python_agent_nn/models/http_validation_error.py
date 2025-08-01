from typing import Any, Dict, Type, TypeVar, TYPE_CHECKING

from typing import List


from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import Union
from typing import Dict
from typing import List
from ..types import UNSET, Unset

if TYPE_CHECKING:
  from ..models.validation_error import ValidationError





T = TypeVar("T", bound="HTTPValidationError")


@_attrs_define
class HTTPValidationError:
    """ 
        Attributes:
            detail (Union[Unset, List['ValidationError']]):
     """

    detail: Union[Unset, List['ValidationError']] = UNSET
    additional_properties: Dict[str, Any] = _attrs_field(init=False, factory=dict)


    def to_dict(self) -> Dict[str, Any]:
        detail: Union[Unset, List[Dict[str, Any]]] = UNSET
        if not isinstance(self.detail, Unset):
            detail = []
            for detail_item_data in self.detail:
                detail_item = detail_item_data.to_dict()
                detail.append(detail_item)






        field_dict: Dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({
        })
        if detail is not UNSET:
            field_dict["detail"] = detail

        return field_dict



    @classmethod
    def from_dict(cls: Type[T], src_dict: Dict[str, Any]) -> T:
        from ..models.validation_error import ValidationError
        d = src_dict.copy()
        detail = []
        _detail = d.pop("detail", UNSET)
        for detail_item_data in (_detail or []):
            detail_item = ValidationError.from_dict(detail_item_data)



            detail.append(detail_item)


        http_validation_error = cls(
            detail=detail,
        )

        http_validation_error.additional_properties = d
        return http_validation_error

    @property
    def additional_keys(self) -> List[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
